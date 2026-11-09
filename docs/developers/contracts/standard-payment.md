# Standard payment contract

`PolygonStandardPayment` settles single-recipient payments: the payer
transfers the total amount, the contract sends the platform fee and the net
amount out in the same transaction, and emits one event. It is the contract
behind ordinary hosted-checkout payments.

| Network | Address |
| --- | --- |
| Polygon mainnet (137) | `0x7AB120ac5060997B5c9AB2F3e891273dd686b8A2` |
| Amoy testnet (80002, sandbox) | `0x8414b029Fe4E50aA93d4F4Cb2E31ADE676CA5502` |

## Settlement flow

1. The payer approves the token amount for the contract from their wallet.
2. The checkout dApp calls `processPayment` with the operation id, token,
   amount, and recipient.
3. The contract pulls `amount` from the payer, sends `feeAmount` to the fee
   recipient and `netAmount` to the recipient, and emits `PaymentProcessed`.
4. If any transfer fails, the transaction reverts: the payer keeps the tokens
   and nothing is settled.

## Functions

| Function | Access | Description |
| --- | --- | --- |
| `processPayment(uint128 operationId, address token, uint256 amount, address recipient)` | anyone | Settles the payment atomically; returns `true` |
| `calculateAmounts(uint256 amount)` | view | Returns `(feeAmount, netAmount)` for the current fee — off-chain preview |
| `setFeeRecipient(address newFeeRecipient)` | owner | Changes the fee recipient for future payments |
| `recoverTokens(address token, uint256 amount)` | owner | Recovers tokens sent to the contract by mistake |
| `recoverPOL()` | owner | Recovers the native balance (the contract does not accept POL) |
| `pause()` / `unpause()` | owner | Emergency stop: pauses or resumes settlement |

## Fee

- `FEE_BASIS_POINTS = 50`, `BASIS_POINTS_DIVISOR = 10000` → **0.5%** of the
  payment amount — the only platform fee.
- `feeAmount = amount × 50 / 10000`, `netAmount = amount − feeAmount`, computed
  in integer base units inside the contract.
- If the computed fee rounds down to zero (dust-sized amounts), the entire
  amount goes to the recipient.
- Fee and net transfers are atomic — see
  [Networks, tokens, and fees](../../payments/networks-tokens-fees.md#fees).

## Events

| Event | When |
| --- | --- |
| `PaymentProcessed(uint128 indexed operationId, address payer, address recipient, address token, uint256 totalAmount, uint256 feeAmount, uint256 netAmount)` | After a successful settlement |
| `FeeRecipientUpdated(address indexed previousFeeRecipient, address indexed newFeeRecipient)` | The owner changed the fee recipient |
| `TokensRecovered(address indexed token, uint256 amount)` | The owner recovered tokens |
| `POLRecovered(uint256 amount)` | The owner recovered the native balance |

`operationId` is the payment identifier used by the API and webhooks. The x402
gateway clone emits the **same `PaymentProcessed` signature**, so one event
listener covers both flows.

## Errors

| Error | Cause |
| --- | --- |
| `InvalidAmount` | `amount` is zero |
| `InvalidRecipient` | `recipient` is the zero address |
| `InvalidAddress` | `token` is the zero address |
| `TransferFailed` | A token transfer failed (missing allowance or balance) |
| `NativeTokenNotAccepted` | Native POL was sent to the contract |
| `NoPOLToRecover` | The owner called `recoverPOL` with nothing to recover |
| `ETHTransferFailed` | The native-balance recovery transfer failed |

!!! note "Operation ids are not checked by this contract"
    The standard contract does not record operation ids — replay protection for
    ordinary payments lives in the API (see
    [Idempotency and retries](../../payments/idempotency-and-retries.md)).
    The split contract does enforce one payload per operation id.

## Security properties

- `nonReentrant` — reentrancy guard around settlement.
- `whenNotPaused` — settlement stops instantly when the owner pauses.
- `SafeERC20` transfers; the fee and the net amount leave the contract in the
  same call, so no balance accumulates between transactions.

## Related sections

- [Contracts overview](index.md) · [Split payment](split-payment.md)
- [x402 gateway and Factory](x402-gateway.md)
- [Create a payment](../../payments/create-payment.md)
- [Security for developers](../security.md)
