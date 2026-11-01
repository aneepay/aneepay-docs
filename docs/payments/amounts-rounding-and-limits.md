# Amounts, rounding, and limits

One payment amount passes through four layers: your request → the API → the
database → the smart contract. Each layer has explicit rounding rules.

## At the API layer

- `amount` must be a decimal **greater than zero**. It may be sent as a JSON
  number or a numeric string.
- It is **rounded to 2 decimal places** with `ROUND_HALF_UP` (banker's-style
  half-up: `0.005` → `0.01`) as soon as the request is validated.
- Values are serialized back as strings with at least two fraction digits and
  no unnecessary trailing zeros (`19.50`, `10.00`).
- No explicit maximum amount is enforced by the schema.

```python title="Rounding" linenums="1"
from decimal import Decimal, ROUND_HALF_UP

def round_amount(value: Decimal) -> Decimal:
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

assert round_amount(Decimal("19.5")) == Decimal("19.50")
assert round_amount(Decimal("0.005")) == Decimal("0.01")
assert round_amount(Decimal("1.234")) == Decimal("1.23")
```

## In the database

- The amount column is `Numeric(16,6)` — up to **6 decimal places** are
  stored, so micro-amounts used by machine payments (e.g. `0.0005`) are not
  truncated.
- API responses re-format the stored value: minimum 2 digits, trailing zeros
  stripped (`19.500000` → `19.50`, `0.000500` → `0.0005`).

## On-chain (the contract)

The contract works in **base units** — integer token units after multiplying
by `10^decimals` (USDT/USDC: 6, DAI: 18). The 0.5% fee uses integer
arithmetic:

```text
feeAmount = amountWei × 50 / 10000      # integer division, rounds down
netAmount = amountWei − feeAmount
```

Consequences:

- The fee is **floored**: dust below the smallest base unit of the fee is
  never charged (for 6-decimal tokens, amounts below `0.0002` produce a zero
  fee). This is expected contract behavior, not a bug.
- In **split** payments, per-recipient share amounts are also integers; any
  division remainder is given to the **last recipient**, so no dust accumulates
  on the contract.
- `amount == 0` reverts (`InvalidAmount`); the API rejects it earlier with
  422 anyway.

## `description` limits

- Optional, default empty.
- Maximum **500** characters; longer values are rejected with 422.
- The text is **public** (checkout page, public status endpoint) — put an
  order number or short item name there, never personal data. See
  [Security and privacy](security-and-privacy.md).

## Other limits

| Limit | Value | Where enforced |
| --- | --- | --- |
| `amount > 0` | required | API (422) and contract (revert) |
| Split recipients | 1..100 | API (422) and contract (`MAX_RECIPIENTS`) |
| Split shares | 1..10000 each, sum = 10000 | API (422) and contract |
| `token` | `usdt`\|`usdc`\|`dai` | API pattern (422) |
| `network` | `polygon`\|`amoy` | API pattern (422) |
| CSV export rows | ≤ 10 000 per file | Dashboard ([export](reconciliation.md)) |

## Practical guidance

- Keep amounts in decimal types on your side; never convert to binary floats.
- Compare amounts as strings or decimals in reconciliation code — the list
  endpoint returns `amount` as a string.
- For machine-scale micro-payments, prefer the [x402](../x402/index.md) flow,
  which is built for sub-cent amounts.

## Related

- [Networks, tokens, and fees](networks-tokens-fees.md) — addresses and decimals.
- [Create a payment](create-payment.md) — request schema.
