# Split payments

A split payment distributes one checkout across several wallets: the customer
pays the total amount once, the 0.5% fee is deducted on-chain, and the
remaining net amount is transferred to each recipient by their share.

Create them with `POST /payments/split/` — a separate endpoint from Standard
payments because the request carries recipient data with its own invariants.

## Request

Same authentication and headers as [Create a payment](create-payment.md):
`X-Account-Id` (required), optional `Origin`, optional `?sandbox=yes`.

### Body

All Standard fields (`amount`, `token`, `network`, `description`), plus:

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `recipients` | array | **Yes** | **1..100** unique EVM addresses, each with a `share`. |

Each recipient:

| Field | Type | Rules | Example |
| --- | --- | --- | --- |
| `address` | string | `0x` + 40 hex chars, not the zero address; normalized to lowercase; must be unique within the payment. | `0x1111…1111` |
| `share` | integer | **1..10000** basis points; the sum across all recipients must equal exactly **10000**. | `7000` |

**The account's `wallet` must appear among the recipients with `share > 0`.**
A merchant always receives a share; a payment that omits the owner is rejected
with **422** (service-level check, RFC 7807).

## Example

```bash title="Terminal"
curl -X POST "https://api.aneepay.com/payments/split/" \
  -H "X-Account-Id: <your-account-uuid>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": "19.50",
    "token": "usdt",
    "network": "polygon",
    "description": "Order #123456",
    "recipients": [
      {"address": "0x1111111111111111111111111111111111111111", "share": 7000},
      {"address": "0x2222222222222222222222222222222222222222", "share": 3000}
    ]
  }'
```

## Response

Identical shape to Standard creation — `id`, `operation_id`, `status`,
`checkout_url`. The payment type differs: it is `B` ("Splits Payment") in
[`GET /payments/{id}`](status-and-polling.md).

## What happens on-chain

The customer's `checkout_url` dApp calls
`processSplitPayment(operationId, token, amount, recipients[], shares[])`
on the `PolygonSplitPayment` contract:

1. The 0.5% fee is withheld from the total, exactly like a Standard payment.
2. The net amount is split by `share` in basis points; **rounding remainder
   goes to the last recipient**, so the contract never accumulates dust.
3. The contract validates everything **before** any transfer (amounts, token,
   recipients, share sum, `MAX_RECIPIENTS = 100`), then pays each recipient
   with a separate `safeTransfer` and emits `RecipientPaid` per wallet.
4. `SplitPaymentProcessed` carries `feeAmount`, `netAmount`, `recipientCount`,
   and `recipientsHash = keccak256(abi.encode(recipients, shares))` — the
   commitment that binds the confirmation to exactly these recipients and
   shares.

Sandbox splits work on Amoy with the same parity as Standard payments.

## Response of the status endpoint (split specifics)

```json title="response.json"
{
  "payment_type": "B",
  "payment_type_display": "Splits Payment",
  "payment_details": {
    "amount": "19.50",
    "token": "usdt",
    "network": "polygon",
    "description": "Order #123456",
    "recipients": [
      {"address": "0x1111…1111", "share": 7000},
      {"address": "0x2222…2222", "share": 3000}
    ]
  }
}
```

After confirmation, `fee` and `net_amount` are added as for Standard payments.

!!! warning "Recipient structure is public"
    `recipients` are stored in `payment_details` and returned by the public
    [`GET /payments/{id}`](status-and-polling.md). The split layout is
    public data — never put personal information in addresses or related
    fields (see [Security and privacy](security-and-privacy.md)).

## Rules and limits

| Rule | Value |
| --- | --- |
| Recipients | 1..100 (gas-bounded: one `safeTransfer` per recipient). |
| Shares | Integers 1..10000, sum **exactly** 10000 (bps; 10000 = 100%). |
| Owner | `account.wallet` must be a recipient with `share > 0`. |
| Addresses | Unique, non-zero, case-insensitive comparison. |
| Immutability | Once the transaction is on-chain, recipients are fixed; verify addresses before creating the payment — they are your responsibility. |

## Errors

| Status | `code` | When |
| --- | --- | --- |
| `403` | `account_not_found` | `X-Account-Id` is missing or unknown. |
| `403` | `account_not_safe` | The account's domain is flagged `is_safe: false` (production). |
| `403` | `domain_mismatch` | The request carries an `Origin` header that does not match the account's domain. |
| `422` | `validation_error` | Share sum ≠ 10000, bad/zero/duplicate addresses, out-of-range `share`, or any other schema violation. |
| `422` | `split_owner_not_recipient` | The account wallet is missing from `recipients`. |
| `422` | `split_sandbox_unsupported` | Sandbox split contract is not available for the account. |
| `500` | `internal_error` | Server-side error during initialization. |
| `503` | `split_payment_unavailable` | Split payments are not available on this network. |

## Why a separate endpoint

Splits use their own request schema because recipients add invariants (share sum,
owner inclusion) that would make the Standard payment contract conditional and
risky for existing clients. The separate schema keeps Standard stable and split
validation explicit (`sum(share) == 10000`), while both payment types share the
same status and webhook model.

## Replay protection

Unlike the Standard contract, the split contract tracks
`usedOperationKeys[keccak256(operationId, token, amount, recipientsHash)]`:
the same operation with the same parameters cannot be paid twice, while a
different recipient set cannot burn someone else's `operationId`.
See [Idempotency and retries](idempotency-and-retries.md).

## Related

- [Reconciliation](reconciliation.md) — filter by `type=B`.
- [Amounts, rounding, and limits](amounts-rounding-and-limits.md).
