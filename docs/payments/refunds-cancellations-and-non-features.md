# Refunds, cancellations, and non-features

AneePay is a minimal on-chain payment gateway. Knowing what it **does not**
do is as important as knowing what it does — several behaviors common in
card gateways are deliberately absent.

## No refunds

There is **no refund API, UI, or operation**. Once a payment is `success`,
the funds have been transferred on-chain to the merchant wallet (minus the
0.5% fee) and the transaction cannot be reversed.

If a customer deserves money back, the merchant refunds them **off-chain**:
transfer the agreed amount back from their own wallet. AneePay does not
record or report these manual refunds; track them in your own order system.

## No customer cancellation

A customer **cannot cancel** a payment:

- There is no cancel endpoint.
- The hosted checkout has no cancel button — the customer can simply close
  the tab, which leaves the payment `pending`.
- No webhook or status change is ever triggered by a customer abandoning a
  payment.

The internal status `cancelled` exists only for **admin/manual operations**
by the AneePay team; it is not part of the merchant-facing contract and
merchants should not expect it.

**What this means for you:** a `pending` payment may sit forever. Set your
own expiry policy — e.g. treat payments still `pending` after N minutes as
abandoned, and never reserve stock until the payment is `success`.

## No subscriptions or recurring payments

Every payment is a **one-off checkout**: a fixed amount, a fixed token, a
fixed recipient. There is no scheduling, no interval, no stored mandate, no
recurring billing, and no tokenized card-like credentials. To run a
subscription, create a new payment for each billing period from your backend
and track the schedule yourself.

## No custody, no withdrawal

Funds go **directly from the customer's wallet to the merchant wallet** in a
single atomic transaction. AneePay never holds balances on behalf of
merchants and provides no withdrawal or payout endpoint. This is the meaning
of "non-custodial" here.

## No fiat on-ramp

Customers pay in USDT, USDC, or DAI on Polygon. There are no card payments,
bank transfers, or automatic conversion for the customer (see
[Networks, tokens, and fees](networks-tokens-fees.md)).

## No native-token payments

The payment contracts accept **ERC-20 tokens only**. Sending POL (the native
token) to the contract address reverts.

## Summary table

| Feature | Status |
| --- | --- |
| Refunds | Off-chain, merchant-initiated; not an API feature |
| Customer cancel | Not supported; abandoned checkouts stay `pending` |
| `cancelled` status | Internal/admin only; not a merchant scenario |
| Subscriptions / recurring | Not supported |
| Custody / withdrawal | Not supported (non-custodial) |
| Fiat payments | Not supported |
| Native token (POL) payments | Rejected by the contract |
| Partial captures / auth-then-capture | Not supported (single atomic payment) |

## Related

- [Payment lifecycle](../getting-started/payment-lifecycle.md) — how `pending` resolves.
- [Security and privacy](security-and-privacy.md) — data exposure boundaries.
