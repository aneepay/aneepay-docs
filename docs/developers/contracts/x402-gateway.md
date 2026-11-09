# x402 gateway and Factory

x402 payments settle through a **per-merchant gateway clone** created by a
public Factory contract. This page is the contract-level reference: functions,
events, errors, and addresses. For the merchant-facing view (clone lifecycle,
deterministic addresses, upgrade policy), see
[Gateway contracts](../../x402/gateway-contracts.md).

## Addresses (Polygon mainnet)

| Contract | Address |
| --- | --- |
| `PolygonX402Gateway` (implementation) | `0x4Be1f3E654C44239757325BDb3d7a839178F782F` |
| `PolygonX402GatewayFactory` | `0x7eAbb924A1f02B8f46d6cbDbC74a29444e09a877` |
| Settlement token (USDC) | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` |
| Fee recipient | `0x0A53C0FAD64C55cEB35dd48774c6435bf9cB0009` |

Gateway clones are deployed on mainnet only; the Amoy testnet has no factory
and is not serviceable for x402.

## Gateway clone

An EIP-1167 minimal proxy of the implementation, initialized **in the same
transaction** in which it is created. After initialization the clone holds:

- `merchant` — receives the net amount; **immutable** for the life of the clone;
- the facilitator address — the only account that may settle;
- `token` — the single whitelisted ERC-20 for this clone;
- `factory` — the creating factory;
- `feeRecipient` — receives the 0.5% fee.

### Settlement functions

Both settlement functions are callable **by the facilitator only**, guarded by
`whenNotPaused` and `nonReentrant`, and both validate that `from` and `value`
are non-zero:

| Function | Scheme | Description |
| --- | --- | --- |
| `processPaymentWithAuthorization(uint128 operationId, address from, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, bytes signature)` | `exact` (EIP-3009) | Calls `transferWithAuthorization` on the whitelisted token; the signature must be exactly 65 bytes |
| `settleWithPermit(uint128 operationId, address from, uint256 value, bytes permitData)` | `permit` (EIP-2612 style) | Executes the permit calldata against the token, then pulls `value` with `transferFrom` |

On success the clone sends the fee to `feeRecipient`, the net amount to
`merchant`, and emits `PaymentProcessed(operationId, payer, merchant, token,
value, feeAmount, netAmount)` — the **same event signature as the standard
payment contract**, so one listener covers both flows.

### Other gateway functions

| Function | Access | Description |
| --- | --- | --- |
| `calculateAmounts(uint256 amount)` | view | Returns `(feeAmount, netAmount)` — off-chain preview |
| `setFeeRecipient(address)` | facilitator | Updates the clone's fee recipient |
| `pause()` / `unpause()` | facilitator | Stops or resumes settlement for this clone |
| `recoverTokens(address token, uint256 amount)` | facilitator | Recovers tokens sent to the clone by mistake |

The merchant address cannot be changed after initialization; the upgrade
policy in [Gateway contracts](../../x402/gateway-contracts.md) explains how an
account moves to a new clone.

## Factory

| Function | Access | Description |
| --- | --- | --- |
| `createCloneFor(uint256 accountId, address merchant)` | facilitator | Deploys a clone with `salt = bytes32(accountId)` and initializes it **atomically** — nobody can initialize the freshly deployed clone first with a different merchant. Emits `CloneCreated` |
| `predictClone(uint256 accountId)` | view | Returns the clone's address before it exists (CREATE2 is deterministic) |
| `setFeeRecipient(address)` | owner | Fee recipient for **new** clones |
| `setToken(address)` | owner | Settlement token for **new** clones; existing clones keep theirs |
| Rotate the facilitator address | owner | Globally for new clones, or per existing clone; per-clone rotation of an address that is not a factory clone reverts |

The settlement token is one whitelist shared by all clones created by this
factory.

### Factory events

| Event | When |
| --- | --- |
| `CloneCreated(uint256 indexed accountId, address indexed clone, address indexed merchant)` | A clone was deployed and initialized |
| `FeeRecipientUpdated`, `TokenUpdated` | Factory-wide defaults changed |
| Facilitator-rotation events | The facilitator address changed (globally or for one clone) |

### Errors

| Error | Cause |
| --- | --- |
| `InvalidAddress` | A zero address passed to `initialize` or an admin setter |
| `Unauthorized` | A caller outside the facilitator role attempted settlement or a facilitator-only action |
| `NotClone` | Per-clone administration for an address the factory did not create |
| `InvalidSignatureLength` | The EIP-3009 signature is not exactly 65 bytes |
| `InvalidAmount` | The settlement value is zero |
| `PermitFailed` | The permit call against the token reverted |
| `NativeTokenNotAccepted` | Native POL was sent to the clone or the implementation |

## Related sections

- [Gateway contracts, merchant view](../../x402/gateway-contracts.md)
- [Facilitator API](../../x402/facilitator-api.md)
- [x402 security](../../x402/security.md)
- [Contracts overview](index.md)
