# Split payment contract

`PolygonSplitPayment` settles one payment across up to 100 recipients with
per-recipient shares. It is the contract behind
[split payments](../../payments/split-payments.md).

| Network | Address |
| --- | --- |
| Polygon mainnet (137) | `0x104e5C8A3C04f1cE4919BBF0b33bd81FF8c49841` |
| Amoy testnet (80002, sandbox) | `0x102078BE0BB620eb3DdAa18B43fb048935e4eB13` |

## Settlement flow

1. The payer approves the total amount for the contract.
2. `processSplitPayment` is called once with the full payload: operation id,
   token, total amount, recipients, and shares.
3. The contract validates the payload, computes the fee, pays every recipient
   in the same transaction, and emits `SplitPaymentProcessed` plus one
   `RecipientPaid` per recipient.
4. Any validation failure or transfer failure reverts the whole transaction —
   no recipient is paid partially.

## Shares and limits

| Rule | Value |
| --- | --- |
| Share unit | Basis points; `shares` must sum to exactly `10000` |
| Maximum recipients | `MAX_RECIPIENTS = 100` |
| Recipient addresses | Must be non-zero |
| Zero shares | Allowed — that recipient receives `0` but still appears in the events |
| Rounding | Each recipient gets `net × share / 10000` rounded down; the **last recipient receives the remainder**, so the contract balance ends at zero |
| Operation id | Must be non-zero |

The API adds one rule the contract does not check: your account wallet must be
among the recipients. Otherwise the request fails with
`split_owner_not_recipient` before anything reaches the chain.

## Functions

| Function | Access | Description |
| --- | --- | --- |
| `processSplitPayment(uint128 operationId, address token, uint256 amount, address[] recipients, uint256[] shares)` | anyone | Validates and settles the split atomically |
| `calculateAmounts(uint256 amount)` | view | Returns `(feeAmount, netAmount)` for the current fee |
| `calculateSplit(uint256 netAmount, uint256[] shares)` | view | Returns per-recipient amounts using the same rounding rules — off-chain preview |
| `usedOperationKeys(bytes32 key)` | view | Returns `true` if this exact payload was already settled |
| `setFeeRecipient`, `recoverTokens`, `recoverPOL`, `pause`, `unpause` | owner | Same administration surface as the standard contract |

## Replay protection

Every processed payload stores `keccak256(operationId, token, amount,
recipientsHash)` in `usedOperationKeys`, where `recipientsHash` covers both
the addresses and the shares. Submitting the identical payload again reverts
with `OperationAlreadyProcessed(operationId)`. Changing any field produces a
new key and a valid, first-time operation.

## Events

| Event | When |
| --- | --- |
| `SplitPaymentProcessed(uint128 indexed operationId, address payer, address token, uint256 totalAmount, uint256 feeAmount, uint256 netAmount, uint256 recipientCount, bytes32 recipientsHash)` | After a successful split |
| `RecipientPaid(uint128 indexed operationId, address indexed recipient, address token, uint256 amount)` | Once per recipient — including zero-share recipients, with `amount = 0` |
| `FeeRecipientUpdated(address indexed previousFeeRecipient, address indexed newFeeRecipient)` | The owner changed the fee recipient |
| `TokensRecovered`, `POLRecovered` | The owner recovered accidental transfers |

## Errors

| Error | Cause |
| --- | --- |
| `InvalidOperationId` | `operationId` is zero |
| `InvalidShares` | Arrays are empty, have different lengths, or exceed 100 recipients |
| `InvalidSharesTotal` | Shares do not sum to exactly `10000` |
| `OperationAlreadyProcessed` | This exact payload was already settled |
| `InvalidAmount` | `amount` is zero |
| `InvalidRecipient` | A recipient is the zero address |
| `InvalidAddress` | `token` is the zero address |
| `TransferFailed` | A token transfer failed |
| `NativeTokenNotAccepted` | Native POL was sent to the contract |

## Sandbox

Split payments are a production capability. The sandbox API rejects them with
`split_sandbox_unsupported` — see [Sandbox](../../sandbox.md).

## Related sections

- [Contracts overview](index.md) · [Standard payment](standard-payment.md)
- [Split payments, merchant guide](../../payments/split-payments.md)
- [Amounts, rounding, and limits](../../payments/amounts-rounding-and-limits.md)
