# Partner FAQ

Questions grouped by topic. Short program-wide answers also live in the
main [FAQ — Partners](../faq.md#partners); this page goes deeper on the
mechanics.

## Getting started

### How do I join?

Enter your email on the registration page and press **Get Partner Link**, then
open the magic link in the email within 10 minutes. The link is single-use and
valid for 10 minutes. Registration is passwordless — there is no password to
set. See [Getting started](getting-started.md).

### Do I need an AneePay merchant account?

No. The partner program is separate: you refer merchants, you do not have to
process payments yourself.

### Do I need a wallet immediately?

No. You can register and confirm your email first. Commissions accrue without
a wallet, but the **Withdraw to Wallet** button stays disabled until you save
a Polygon address.

### I lost the magic link. What now?

Request a new one from the registration page. Registering again with the same
email does not create a duplicate partner profile.

### Why does the dashboard send me back to registration or wallet setup?

| Redirected to        | Reason                                                  |
| -------------------- | -----------------------------------------------------   |
| Registration         | The profile is still `Pending` — confirm the magic link |
| Wallet setup         | No wallet address is on file yet                        |
| Landing page         | You are not signed in                                   |

## Attribution

### How does a merchant become "mine"?

Your link carries `?ref=<your-partner-id>`. Visiting any page with it stores a
referral cookie valid for **30 days**. The attribution becomes permanent when
the merchant **creates their account** while that cookie is still valid.

### Does clicking my link alone attribute the account?

No. The cookie only records the visit. The account must be created while the
cookie is valid for the binding to happen.

### What if the merchant already visited before?

The **first** link wins. A later visit with a different `?ref=` does not
overwrite an existing cookie, and an account that is already attributed is
never re-attributed.

### What if the merchant returns weeks later, without my link?

Attribution is permanent. Once the account is bound to you, every qualifying
payment it makes earns you a commission — there is no expiry on the
attribution itself (only the initial 30-day cookie window has one).

### What if my `?ref=` is unknown or my profile is not active?

Unknown, invalid, or `Pending` partner IDs are ignored: no cookie is stored
for them, and no account is bound to them.

## Commissions

### How much do I earn?

**10% of the platform fee** — the platform charges 0.5%, so your share is
≈**0.05% of the merchant's turnover**. Your profile may carry an individual
share; the dashboard always shows yours as `Share of fee`.

### When is a commission earned?

Only for a payment that is **confirmed** and **success**. Failed or pending
payments never accrue a commission.

### When can I withdraw it?

7 days after the payment is confirmed. Until then it appears under
`In 7-day hold`; afterwards it moves to `Available to Withdraw`. Details and
worked examples are on [Commissions and payouts](commissions-and-payouts.md).

### Why did my "In 7-day hold" number drop while "Available" grew?

That is the hold expiring: commissions move from the hold to the available
balance as they pass 7 days.

### Do I earn on refunds or disputed payments?

A commission exists only for payments in the `success` state. Anything that is
not a confirmed success earns nothing.

## Payouts

### What token and network?

**DAI on Polygon** (Amoy testnet while the platform is in testing). Gas is
covered by AneePay; the transfer is sent from an AneePay payout wallet.

### Is there a minimum payout or a fixed schedule?

No minimum and no fixed interval — press **Withdraw to Wallet** whenever you
want. A withdrawal sweeps the entire available balance in one transfer.

### How long does a payout take?

The withdrawal is queued immediately and sent on-chain shortly after. The
payout appears in **Payout History** as `Pending`, then `Processing`, then
`Paid` once the transaction is confirmed.

### My payout shows `Failed`. Is the money lost?

No. The commissions from a failed payout return to your available balance and
are included in the next accrual or your next withdrawal attempt. The
transfer is retried safely — the transaction hash and nonce are recorded
before broadcasting, so a payout can never be sent twice.

If it fails repeatedly, check the wallet address and contact support with the
payout date and amount.

### Can I change the payout address?

Set the wallet during the initial setup; it is shown on the dashboard under
**Your Info**. If you need to change it after that, contact support.

### Where can I see what I have been paid?

The **Payout History** card on the dashboard lists your last 10 payouts with
date, amount, status, and transaction hash. Lifetime totals are in the
`Accrued` and `Paid` counters.

## Account

### What do the statuses mean?

| Status     | Meaning                                                            |
| ---------- | ----------------------------------------------------------------   |
| `Pending`  | Registered, waiting for the magic link to be confirmed             |
| `Active`   | Earning and payable — set automatically when the link is confirmed |
| `Disabled` | Accruals are paused; contact support to re-enable                  |

Only `Active` partners accrue commissions, and the dashboard requires
`Active` status plus a wallet.

### Can I have two partner profiles for one email?

No. Registering again with an existing email reuses the same partner profile.

### How many merchants can I refer?

As many as you like — there is no cap on referred merchants, on earnings, or
on how long attribution lasts.

## Related sections

- [Partner overview](index.md) — how the program works at a glance.
- [Getting started](getting-started.md) — registration and referral link.
- [Commissions and payouts](commissions-and-payouts.md) — accrual, hold,
  withdrawals.
- [FAQ — Partners](../faq.md#partners) — short answers in the main FAQ.
