# Beta limitations

!!! warning "The CMS plugins are in beta"

    The payment flow itself is complete: a customer can pay in USDT, USDC or
    DAI, the webhook is verified, the order changes state, stock is released
    on a failure, and the result page always shows the real outcome. Every
    plugin has been run end to end against a shop with a real sandbox
    payment.

    What is still settling is the polish around it — admin tooling, extra
    locales, older platform versions — and this documentation. Read the list
    below before taking live payments, and treat an upgrade as a change worth
    testing on a staging shop first.

## What is not implemented

| Area | What to know |
| ---- | -------------------- |
| Refunds | There is no refund or cancellation call to the AneePay API. Refund the customer from your own wallet and change the order state by hand; the plugin leaves the order alone; `success` is the only status it treats as final. |
| Partial payments | A payment is for the whole order total. There is no "pay the rest later" flow and no partial refund tracking. |
| Subscriptions and recurring | No token vault, no stored credentials, no scheduled charges. Each order is a single payment. |
| Fiat / cards | Crypto only: USDT, USDC and DAI on Polygon. No card acquiring, no bank transfer. |
| WooCommerce blocks checkout | The gateway renders in the **classic** checkout only. A shop that runs the block-based Cart/Checkout page does not show AneePay among the payment methods. |
| OpenCart 4 | Only OpenCart 3.0.x is supported. OpenCart 4 changed the extension API and is not covered; the plugin also pins PHP 7.4 because OpenCart 3 does not run on PHP 8. |
| Other platforms | Shopware, Magento, Bitrix and everything else have no plugin. Use the [custom integration recipe](custom-integration.md) — it is the same flow the plugins implement. |
| Locales | All shopper-facing strings ship in English. WooCommerce and PrestaShop can be translated through their normal mechanisms; OpenCart ships `en-gb` only. |
| Multiple currencies | The store total is converted to USD, then to the token. Currencies outside the ECB list (RUB, UAH and so on) cannot use the automatic rate and fall back to the store rate, then to the manual rate. |

## What behaves differently from what you might expect

### Only a successful payment is ever pushed to your shop

The platform sends a webhook when a payment **succeeds**. A failed or expired
payment produces no webhook at all, so the plugin learns about it in two other
ways:

- the result page asks the API for the payment status before it renders, so a
  buyer who lands there sees the real outcome;
- the cron job polls pending orders and applies the status it reads.

This is why the plugins ship with a cron URL and why "paid but still pending"
almost always means the webhook never arrived — see
[Troubleshooting](troubleshooting.md).

### There is no TTL on the AneePay side

A payment stays payable until it is paid or until your shop decides it is
abandoned. That decision belongs to the plugin: after **Abandoned Payment
Expiry** minutes (default 120, `0` disables it) the cron job closes the order —
but only after the API confirms the payment did not go through. A timeout, a
`5xx` or a `429` leaves the order pending for the next run.

WooCommerce closes an abandoned payment as **failed**; OpenCart and PrestaShop
close it as **cancelled**, or as failed when no cancelled status is configured.

### Abandoned order: what the customer sees

The buyer is never sent back to checkout after paying. The result page shows
the state that the server resolved, and the "Try again" link appears **only**
for a failed payment. Polling stops after 30 minutes and offers an explicit
**Check again** button instead of hammering your server forever.

### No idempotency key on the API

AneePay does not accept an `Idempotency-Key`, so the plugins guard themselves:
a mapping row in the `creating` state locks the order while the payment is
created, and if the API answer is lost (timeout, unreadable body) the plugin
looks for the payment in the account list by amount and order reference
instead of retrying blind. A double click or a second tab cannot start a
second payment.

### A webhook is delivered once

There is no replay endpoint. If a delivery is lost for good, open the plugin
settings and use **Reconcile payments** — it reads the account payment list
for the last 1–30 days and applies the status of every payment it can match to
an order.

### Sandbox always uses USDC

Test mode runs on Polygon Amoy and forces USDC regardless of the configured
token, so a sandbox payment has to be made with USDC. A sandbox payment never
completes a live order, and a live payment never completes a sandbox order: the
`is_sandbox` flag of the payload is compared with the order's own flag.

### Fee

AneePay charges 0.5% per transaction, and that is the only fee the plugins
model. There is no per-store fee rule in any of the three plugins — the field
that once promised one in OpenCart never affected the amount and has been
removed.

## Version and platform notes

| Platform | Tested with |
| -------- | ----------- |
| WooCommerce | WordPress 6.0+ (the plugin header says tested to 9.4 for WooCommerce 6.0+) |
| OpenCart | 3.0.3.8 on PHP 7.4 |
| PrestaShop | 8.1.7 on PHP 8.1; 1.7.x is supported but not covered by the test shop |

WooCommerce declares compatibility with High-Performance Order Storage (HPOS);
OpenCart and PrestaShop use their own order tables, plus one mapping table per
plugin (`aneepay_order`, `oc_aneepay_order`, `ps_aneepay_order`).

## Reporting a beta bug

When something looks wrong, collect the order number, the AneePay payment ID,
the timestamp, and the request log from the plugin settings page — the log
never contains your webhook secret. Then [contact support](https://t.me/aneepay).

## Related sections

- [CMS integrations overview](index.md)
- [Troubleshooting](troubleshooting.md)
- [Testing your integration](../testing-your-integration.md)
- [Sandbox](../sandbox.md)
- [Webhooks](../webhooks/overview.md)
