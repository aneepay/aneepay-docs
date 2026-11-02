# Commissions and payouts

This page explains how a commission is calculated, when it becomes available,
and what happens when you press **Withdraw to Wallet**.

## How a commission is calculated

Two numbers matter: the platform fee AneePay charges the merchant, and your
share of that fee.

| Parameter        | Default | Where it comes from                                  |
| ---------------- | ------- | ---------------------------------------------------- |
| Platform fee     | 0.5%    | Charged on every successful payment                  |
| Your share       | 10%     | Your partner profile; the default, may be individual |
| Payout token     | DAI     | On the Polygon network (Amoy during testing)         |
| Amount precision | 6 dp    | Commission amounts are rounded half-up               |

The commission for one payment is:

```text
fee_amount       = gross_amount × 0.005
commission_amount = fee_amount × your_share
```

Example with the default share:

| Payment (gross) | Platform fee (0.5%) | Your commission (10%) |
| --------------- | ------------------- | --------------------- |
| 100.00          | 0.50                | 0.050000              |
| 1 000.00        | 5.00                | 0.500000              |
| 10 000.00       | 50.00               | 5.000000              |

Every commission is recorded against the individual payment that produced it,
so the dashboard totals always reconcile with your payout history.

!!! warning "Only confirmed, successful payments"

    A payment earns a commission only when it is **confirmed** and its status
    is **success**. Failed, pending, or otherwise non-successful payments
    never accrue anything.

## The 7-day hold

A commission does not become withdrawable the moment the payment settles.

| Stage       | Condition                                                     | Shown as                |
| ----------- | ------------------------------------------------------------- | --------------------    |
| On hold     | Payment confirmed and successful, **younger than 7 days**     | `In 7-day hold`         |
| Available   | Payment confirmed and successful, **7 days or older**         | `Available to Withdraw` |
| Paid        | Included in a completed payout                                | `Paid` (lifetime)       |

The hold gives the payment time to settle fully before money moves. The
dashboard shows both numbers side by side:

- **Available to Withdraw** — accrued commissions you can cash out right now.
- **In 7-day hold** — commissions that will become available as the hold
  expires.

Accrual runs automatically for **active** partners; the same accrual also runs
on demand when you press the withdraw button, so nothing is missed between
scheduled runs.

## Withdrawing

1. Open the **Partner Dashboard**.
2. Check **Available to Withdraw**. The **Withdraw to Wallet** button is
   disabled while it is `0.000000`.
3. Press **Withdraw to Wallet**.
4. All available commissions are grouped into a payout and sent to the wallet
   on file as a single DAI transfer.

You will see:

```text
Payout of 0.050000 DAI initiated to 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B
```

If nothing has matured yet:

```text
Nothing to withdraw yet. Commissions become available 7 days after the payment is confirmed.
```

| Property            | Value                                                             |
| -----------------   | --------------------------------------------------------------    |
| Minimum amount      | None — a withdrawal sweeps the whole available balance            |
| Fixed interval      | None — you decide when to withdraw                                |
| Network             | Polygon                                                           |
| Token               | DAI                                                               |
| Gas                 | Covered by AneePay                                                |
| Source of funds     | An AneePay payout wallet                                          |
| Number of transfers | One per withdrawal — all available commissions in a single payout |

!!! warning "A wallet must be on file"

    Without a wallet the withdrawal button stays disabled, but commissions
    keep accruing. Save an address on the wallet setup page to unlock
    withdrawals — see
    [Getting started](getting-started.md#3-set-up-your-payout-wallet).

## Payout history

The **Payout History** card lists your last 10 payouts with the date, amount,
status, and transaction hash. An empty account shows `No payouts yet.`

| Status       | Meaning                                                          |
| ------------ | ---------------------------------------------------------------- |
| `Pending`    | Created, waiting to be processed                                 |
| `Processing` | The transfer is being sent on-chain                              |
| `Paid`       | Confirmed on-chain; the commissions in it are marked as paid     |
| `Failed`     | The transfer did not complete — see below                        |

The transaction hash is shown truncated in the dashboard; it links the payout
to the transfer on the Polygon explorer.

### When a payout fails

A failed payout does not lose money: its commissions go back into your
available balance and are picked up by the next accrual run or your next
withdrawal attempt.

The transfer is retried safely — the transaction hash and nonce are recorded
before broadcasting, so a retry never sends the same payout twice.

If a payout fails repeatedly:

1. Confirm the wallet address on the dashboard is a valid Polygon address.
2. Confirm the address can receive DAI.
3. Contact support with the payout date and amount from the history table.

## What the dashboard counters mean

| Counter               | Meaning                                                             |
| -------------------   | ------------------------------------------------------------------- |
| Referred Merchants    | Accounts permanently attributed to you                              |
| Accrued               | Lifetime commissions earned (available + already paid out)          |
| Paid                  | Lifetime commissions included in completed payouts                  |
| Payouts               | Number of payout transactions, successful or not                    |
| Available to Withdraw | Balance you can cash out right now                                  |
| In 7-day hold         | Commissions still inside the 7-day holding period                   |

## Related sections

- [Getting started](getting-started.md) — registration, magic link, wallet.
- [FAQ](faq.md) — partner questions grouped by topic.
- [FAQ — Partners](../faq.md#partners) — short answers about the program.
