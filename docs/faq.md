# FAQ

Frequently asked questions, grouped by audience. For integration problems see
[Troubleshooting](troubleshooting.md); for the full product model see
[Product overview](getting-started/overview.md).

## General

### What is AneePay?

A strictly non-custodial crypto payment gateway on Polygon. Customers pay in
USDT/USDC/DAI through a hosted checkout; the on-chain contract deducts a flat 0.5%
fee and sends the net amount straight to your wallet. No custody, no KYC, no
chargebacks.

### How much does it cost?

A flat **0.5%** per payment, deducted on-chain by the smart contract. 99.5% goes to
you. There are no setup, subscription, or hidden fees. Network gas is paid by the
**customer** in POL, not by you and not out of the fee.

### Which tokens and networks are supported?

USDT, USDC and DAI on **Polygon PoS** (mainnet). The [sandbox](sandbox.md) uses
test USDC on the **Amoy** testnet.

### How fast are payments?

Polygon blocks are ~2 seconds; the platform requires 12 confirmations before a
payment becomes `success` and the webhook fires — typically a handful of seconds to
about a minute under normal conditions.

### Do I need KYC or business documents?

No. Onboarding is automatic: register with an email (passwordless magic link),
create an account with your domain and wallet. The only check is domain reputation
(Google Safe Browsing) — see [Account setup](getting-started/account-setup.md).

### Are payments really non-custodial?

Yes. Tokens pass through the contract in one atomic transaction and land in your
wallet — they are never held by AneePay. The contract is verified on
[Polygonscan](https://polygonscan.com/address/0x7AB120ac5060997B5c9AB2F3e891273dd686b8A2).

### Can payments be refunded or cancelled?

No. Blockchain transactions are irreversible and the product exposes no refund or
customer-cancel API. Refunds, when needed, are your own off-chain arrangement —
see [Refunds and non-features](payments/refunds-cancellations-and-non-features.md).

### What taxes apply?

Yours. AneePay does not report or withhold anything; consult a local advisor for
your obligations.

### Where can I see the smart contract?

- Standard payments (Polygon): `0x7AB120ac5060997B5c9AB2F3e891273dd686b8A2`
- Split payments (Polygon): `0x104e5C8A3C04f1cE4919BBF0b33bd81FF8c49841`

Both are verified; the Amoy (sandbox) addresses are in
[Networks, tokens, and fees](payments/networks-tokens-fees.md).

## Merchants

### How long does integration take?

One `POST /payments/` call, a redirect to `checkout_url`, and a webhook receiver.
Most teams complete a sandbox pass in an afternoon — start with the
[Quickstart](getting-started/quickstart.md).

### Which wallet receives the funds?

The `wallet` field on your account — changeable any time in dashboard settings.
New payments go to the updated address; the recipient is locked per-payment at
creation time.

### Can I change the recipient address after a payment is created?

No. The contract locks the recipient when the payment is created; this protects
against redirection of funds.

### What is `operation_id`?

The payment UUID encoded as an integer, used on-chain and in webhooks. It is
lossless (`uuid.UUID(int=operation_id)` restores the id) and is the value to store
on your order for correlation — see
[Create a payment](payments/create-payment.md).

### What happens if the customer pays the wrong amount or fails?

A failed or mismatched transaction reverts on-chain: nothing is deducted, no
partial capture exists. Your order stays unpaid; the customer can retry from
`fail_url`.

### Is AneePay suitable for micropayments?

Yes, with one caveat: the 0.5% fee is rounded in whole token units on-chain, so
tiny amounts can round to a **zero fee**. There is no artificial minimum beyond
`amount > 0` — details in
[Amounts, rounding, and limits](payments/amounts-rounding-and-limits.md).

### Why is my account marked "unsafe"?

New or flagged domains get `is_safe: false`; payments return
`403 account_not_safe` until the reputation review passes. `?sandbox=yes` bypasses
the check for testing. If it persists, contact support.

### Where is my payment history?

Dashboard shows all payments with amounts, statuses and links to the explorer.
For programmatic access use
[Reconciliation](payments/reconciliation.md) (`GET /accounts/{account_id}/payments`
and CSV export).

### How do I receive payouts / change my payout address?

AneePay sends funds directly to your account `wallet` per payment — there is no
separate "payout" step for merchants. Update the address in account settings;
already-completed payments stay on the old address.

### Do you have an idempotency key for payment creation?

No — each `POST /payments/` creates a new payment. If the outcome of a request is
unknown, list payments and resolve before retrying — see
[Idempotency and retries](payments/idempotency-and-retries.md).

### How do you compare to Coinbase Commerce / Stripe Crypto / BitPay?

Same niche, different model: flat 0.5% vs typically 1%+, no chargebacks (irreversible
on-chain), no custody, instant settlement to your own wallet, and domain-only
onboarding instead of business verification. We do not hold or convert funds the way
centralized processors do.

## Customers (payers)

### Which wallets can pay?

Any EIP-1193 wallet works in a desktop browser or an in-app browser; the checkout
also discovers wallets through EIP-6963. On mobile, MetaMask is the tested path —
scan the QR code or use the MetaMask deep link. Other mobile wallets are not
currently tested.

### The QR code does not work — what now?

Use the **Pay with MetaMask** button below the QR (it carries the same payload),
make sure the device is online and MetaMask is set to the payment network.

### Do I need an AneePay account to pay?

No. Paying only needs a wallet with tokens and gas.

### Can I change the amount or recipient after the invoice?

No — both are fixed when the payment is created. Send exactly the requested amount
on the requested network; anything else reverts.

### What if my transaction fails or reverts?

Funds stay in your wallet (a revert undoes everything). Fix the cause (balance,
allowance, network, gas) and retry from the checkout page.

## Partners

### What is the partner program?

Refer merchants and earn **10% of the platform fee (0.5%) for life** on every
confirmed payment they process — 0.05% of their turnover. Details in
[Partner program](partner/index.md).

### How does attribution work?

First-touch: a 30-day cookie (`?ref=<id>` link). The first partner link a visitor
clicks wins; once an account is created the attribution is permanent. Existing
accounts cannot be re-attributed.

### When do commissions mature?

Payments must be confirmed on-chain, `success`, and older than 7 days before they
enter the payout cycle. Failed payments never accrue.

### How and in what am I paid?

DAI on Polygon, withdrawn on demand from your partner dashboard ("Withdraw to
Wallet"). Gas for the payout is covered by the platform. A Polygon wallet is
required before payouts — you can register first and add it later.

### What do the statuses mean?

`Pending` (awaiting magic-link confirmation) → `Active` (earning and payable) →
`Disabled` (accruals paused; contact support).

## x402

### What is x402?

An open protocol for machine payments over HTTP built on the `402` status code and
EIP-3009. AI agents and services pay per request in USDC without accounts or API
keys — see [x402](x402/index.md).

### Can my store accept payments from AI agents?

Yes — your resource server challenges with `402`, the client signs a transfer, and
you verify/settle through AneePay's facilitator using your existing account.
Same rails, same 0.5% fee, funds to your wallet.

### Which tokens/networks does x402 support?

USDC with the `exact` scheme (EIP-3009) on Polygon mainnet; Amoy for testing.

### Is x402 non-custodial?

Yes. Each merchant gets a dedicated gateway clone; the payer's transfer settles to
your wallet in the same transaction.

## Still stuck?

- [Troubleshooting](troubleshooting.md) — symptom-by-symptom fixes.
- Support: <https://t.me/aneepay>
