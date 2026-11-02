# Partner program

The AneePay partner program pays you a share of the platform fee for every
payment a merchant you referred processes. You get a referral link, merchants
who sign up through it stay attributed to you for life, and accrued commissions
are paid out in DAI on Polygon whenever you ask for them.

!!! note "No caps, no expiry"

    The share is **10% of the platform fee** on every qualifying payment —
    forever. There is no cap, no expiration date on the attribution, and no
    minimum balance to reach before you can withdraw.

## How it works

| Step | What happens                                                                       |
| ---- | ---------------------------------------------------------------------------------- |
| 1    | You [register](getting-started.md) with an email and confirm the magic link        |
| 2    | You add the Polygon wallet address that should receive DAI payouts                 |
| 3    | You copy your referral link and share it with merchants                            |
| 4    | A merchant who signs up through your link is attributed to you permanently         |
| 5    | Each of their successful payments earns you a commission, held for 7 days          |
| 6    | You press **Withdraw to Wallet** in the dashboard and receive DAI                  |

## What you earn

The platform fee is **0.5%** of each payment. Your share is **10% of that
fee**, which works out to **≈0.05% of the merchant's total volume**.

| Merchant monthly volume (USD) | Platform fee, 0.5% (USD) | Your commission, 10% of the fee |
| ----------------------------  | ------------------------ | ------------------------------- |
| 10,000                        | 50                       | 5.00                            |
| 100,000                       | 500                      | 50.00                           |
| 1,000,000                     | 5,000                    | 500.00                          |

Figures are illustrative, in USD. Commissions are accrued per payment and paid
out in DAI, so the DAI amount of each payout follows the token conversion of
that payment, not this table. Each partner profile may have an individual
share — the default is 10%.

!!! warning "Only successful payments count"

    A commission is accrued only for a payment that is **confirmed** and
    **successful**. Pending and failed payments never generate a commission, and
    a commission is only created once the confirmation is 7 days old.

## Attribution

- Your link carries your partner ID as a `?ref=` parameter, for example
  `https://example.com/?ref=<your-id>`.
- Visiting **any** page with your link stores a referral cookie that lasts
  **30 days**.
- The cookie becomes a permanent attribution when the merchant **creates their
  account** while the cookie is still valid.
- Attribution is **first touch**: a later click on someone else's link does not
  re-attribute the account, and the commission never moves away from you.

See [Getting started](getting-started.md) for the exact flow and
[FAQ](faq.md#attribution) for edge cases.

## Account statuses

| Status     | Meaning                                                           |
| ---------- | ----------------------------------------------------------------  |
| `Pending`  | Registered, waiting for you to confirm the magic link             |
| `Active`   | Earning and payable — set automatically when you confirm the link |
| `Disabled` | Accruals are paused; contact support to have it re-enabled        |

Only **active** partners accrue commissions and can withdraw. The dashboard is
available once your status is `active` and a wallet is on file.

## In this section

| Page                                                   | Covers                                                                |
| ------------------------------------------------------ | --------------------------------------------------------------------- |
| [Getting started](getting-started.md)                  | Email registration, the magic link, wallet setup, your referral link  |
| [Commissions and payouts](commissions-and-payouts.md)  | Accrual, the 7-day hold, available balance, DAI payouts, history      |
| [FAQ](faq.md)                                          | Partner questions grouped by topic                                    |

## Related sections

- [Merchant](../merchant/index.md) — what the merchants you refer are signing
  up for.
- [API reference](../api/index.md) — the payments that generate your
  commissions.
- [FAQ](../faq.md#partners) — short answers about the partner program.
