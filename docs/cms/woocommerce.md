# WooCommerce

The **AneePay Crypto Gateway for WooCommerce** plugin accepts stablecoin payments
(USDT, USDC, DAI) on Polygon through hosted checkout and confirms orders by
webhook. This page covers installation, settings, checkout behavior, order
statuses, and test mode.

!!! warning "Beta"

    The CMS plugins are in beta. The payment flow is complete and tested against
    the three stands in the repository, but the admin tooling and this
    documentation are still settling. Read
    [Beta limitations](limitations-beta.md) before taking live payments.

## Requirements

| Component       | Minimum             | Notes                                                    |
| --------------- | ------------------- | -------------------------------------------------------- |
| WordPress       | 6.0                 | —                                                        |
| WooCommerce     | 6.0 (tested to 9.4) | —                                                        |
| PHP             | 7.4                 | —                                                        |
| AneePay account | —                   | See [Account setup](../getting-started/account-setup.md) |

The plugin declares compatibility with **HPOS** (High-Performance Order Storage)
and stores payment data in order meta, so it works with both the legacy post-based
and the new order tables.

## Installation

1. Download `woocommerce-aneepay-<version>.zip` from the plugin releases.
2. In WordPress admin: **Plugins → Add New Plugin → Upload Plugin** → select the
   zip → **Install Now** → **Activate**.
3. WooCommerce must already be installed and active. If it is not, the plugin shows
   an admin notice and deactivates itself.
4. Open **WooCommerce → Settings → Payments**, enable **AneePay Crypto**, then
   click **Manage** (or **Set up**).

## Settings

Settings live at **WooCommerce → Settings → Payments → AneePay Crypto**.

| Field                          | Required | Purpose                                                                                                       |
| ------------------------------ | -------- | ------------------------------------------------------------------------------------------------------------- |
| Enable/Disable                 | yes      | Master switch for the payment method.                                                                         |
| Title / Description            | no       | What the customer sees on the payment method card.                                                            |
| Account ID                     | yes      | Account UUID; must be a valid UUID or settings are rejected.                                                  |
| Webhook Secret                 | yes      | Signs `X-AneePay-Signature`. Leaving the field blank on re-save keeps the stored value.                       |
| Domain                         | no       | Host sent as `Origin`; empty means "use the site host".                                                      |
| Test/Sandbox Mode              | no       | Adds `?sandbox=yes` to API calls (Amoy + USDC, `is_safe` bypass). Off by default.                             |
| Cryptocurrency                 | no       | `usdt` (default), `usdc`, `dai`. Ignored in sandbox (always USDC).                                            |
| Blockchain                     | no       | `polygon` (default) or `amoy`. Amoy is forced in sandbox.                                                     |
| Exchange Rate Source           | no       | **Auto** (Frankfurter/ECB with manual fallback) or **manual rate only**.                                      |
| Manual Exchange Rate           | no       | Store-currency units per 1 token (≈ 1 USD); must be positive.                                                 |
| Debug Log                      | no       | Logs API calls to **WooCommerce → Status → Logs** (source `aneepay`). Errors are always logged; entries are kept for 14 days. |
| Status Sync Interval           | no       | WP-Cron polling of pending orders: every 5 (default) / 10 / 15 / 30 minutes.                                  |
| Abandoned Payment Expiry       | no       | Minutes after which an unpaid order is failed and its stock released. Default 120; set **0** to disable.      |

The settings page also provides:

- a **SANDBOX / LIVE** badge with the active token and network;
- a **Quick setup** card listing the exact URLs to paste into the AneePay panel;
- a **Test connection** button — it calls
  `GET /accounts/{account_id}/payments`, which validates the account, the `Origin`
  domain, and `is_safe` without creating a payment;
- an **example conversion** preview for the current rate settings;
- a **Request log** panel with the last 50 API calls (never contains secrets);
- a **Sync a payment** panel — enter an AneePay payment ID (and optionally the
  order number) to fetch that payment and apply its status right away. This is the
  manual fix for "the buyer paid but the order is still pending", because the
  platform sends a webhook once and never replays it;
- a **Reconcile payments** panel — compares the store with the payments AneePay
  recorded in the last 1–30 days (default 7) and applies the status of every
  payment it can match to an order. It reports how many payments it checked,
  matched, updated, and could not match. Use it when a webhook was lost for good.

!!! warning "A webhook secret is mandatory"

    Without `Webhook Secret` every webhook is rejected with **401** and orders
    never confirm. The settings page shows an error notice while the secret is
    missing.

## Store URLs for the account panel

The settings page prints these three URLs with **Copy** buttons. Paste them into
the AneePay account panel (`status_url`, `success_url`, `fail_url`):

| Account field  | Store URL                                    |
| -------------- | -------------------------------------------- |
| `status_url`   | `https://<store>/wp-json/aneepay/v1/webhook` |
| `success_url`  | `https://<store>/?aneepay=success`           |
| `fail_url`     | `https://<store>/?aneepay=fail`              |

WP-Cron handles status polling automatically — there is no cron URL to schedule.

## Checkout

1. The customer selects **Pay with Crypto (USDT/USDC/DAI)** and places the order.
2. The plugin converts the order total (store currency → USD → token, rounded
   **up** to 2 decimals) and shows a breakdown on the payment method card:
   "You will pay X TOKEN". The breakdown is an estimate; the amount actually
   charged is fixed when the payment is created.
3. The plugin calls `POST /payments/` **from the store server** with
   `X-Account-Id`, `Origin`, and `description: "Order #<number>"`, then redirects
   the customer to `checkout_url`.
4. The order is set to **pending** with a note containing the AneePay payment ID,
   and product stock is reduced.
5. The order-received page polls the status while the customer waits.

**Idempotency:** if an order already has a pending AneePay payment, a reload or
double click reuses the existing `checkout_url` instead of creating a second
payment. A mapping row in the `creating` state locks the order while the payment
is being created, so two tabs cannot start two payments. If the API answer is lost
(timeout, unreadable body), the plugin looks the payment up in the account list by
amount and order reference instead of retrying blind.

### Result pages

`/?aneepay=success` and `/?aneepay=fail` identify the order from a signed cookie
set at checkout. The cookie lives **24 hours** and is renewed on every visit (at
most once a minute), so a buyer who pays from an exchange or a wallet app and comes
back much later still sees the right page.

Before rendering, the page fetches the payment from the API — a failed payment is
only ever visible through the API, because a webhook is sent on `success` alone.
The page therefore shows one of three states:

- **paid** — the payment succeeded (a webhook that arrived during the redirect is
  reflected too);
- **failed** — the payment failed or was cancelled, with a **Try again** link back
  to checkout and no "I already paid" button, so a buyer who actually paid is never
  sent to pay twice;
- **pending** — still waiting for the on-chain transaction.

While the state is pending the page polls the status: after 5 seconds, then after
15, then every 30 seconds, for at most 30 minutes. When that budget is spent the
polling stops and an explicit **Check again** button appears; pressing it also
resets the budget. Polling only adds convenience: the server resolves the status on
every page load, so reloading the page always gives the current state, with or
without JavaScript.

The status endpoint (`action=aneepay_check_status`) requires the WooCommerce order
key or the owning customer, so another visitor cannot poll or advance an order.

!!! note "Block-based checkout"

    The plugin integrates with the classic checkout. If your store uses the
    block-based Cart/Checkout blocks and AneePay does not appear, switch that page
    to the classic checkout shortcode.

## Order statuses

| Payment status | WooCommerce effect                                                                          |
| -------------- | ------------------------------------------------------------------------------------------- |
| `pending`      | Order stays **pending**; note: "Awaiting crypto payment…"                                   |
| `success`      | `payment_complete()` — order moves to processing/completed; **terminal, never downgraded**   |
| `failed`       | Order → **failed**; reserved stock is restored exactly once                                  |
| `cancelled`    | Order → **cancelled**; reserved stock is restored exactly once                               |

Notes:

- The payment status is stored on the order as `_aneepay_payment_status`;
  `_aneepay_payment_id` and `_aneepay_operation_id` link the order to the API
  record.
- Applying the same status twice is a no-op, so redelivered webhooks are harmless.
- `success` is final: a later `pending` or `failed` for the same payment does not
  downgrade a paid order.
- `failed` and `cancelled` never arrive from the platform on their own: a payment
  only moves `pending → success` once the on-chain event confirms. Both mappings
  are there for records an operator changes manually in the AneePay admin and for
  the abandoned-payment expiry below.
- Unknown statuses are ignored.
- Every change writes an order note (`AneePay: payment confirmed.`, `… failed.`,
  `… cancelled by the customer.`) so the history explains what happened.

## Webhook

The plugin registers a public REST route:

```text
POST /wp-json/aneepay/v1/webhook
```

Processing:

1. **Signature is verified first** (fail-closed): `X-AneePay-Signature` must be
   the HMAC-SHA256 of the raw body keyed with `Webhook Secret`. Missing secret,
   missing header, or mismatch → **401**, nothing is processed.
2. The event is deduplicated by `event_id` (or by a hash of the body for legacy
   payloads) in the `{prefix}aneepay_event` table. A retry of an event that was
   already applied gets **200 `{ "success": true, "duplicate": true }`** and
   changes nothing. Rows are pruned after 7 days.
3. `operation_id` is decoded as a 128-bit integer string (never as a float).
4. `timestamp` is informational: when `version` and `event_id` are present it must
   be there, numeric, and not negative, otherwise **400**. Authorisation is the
   signature alone; there is no freshness window, and replays are stopped by the
   deduplication above.
5. The order is resolved in this order: `order_id` → `payment_id` →
   `operation_id` → `operation_id` decoded back to the payment UUID →
   `description: "Order #N"`. Only orders paid with this gateway qualify.
6. A sandbox payment never completes a live order: when the payload says
   `is_sandbox: true` (or `network: amoy`) and the order was created live, the
   delivery is acknowledged but not applied.
7. The status is applied idempotently; a matching `200 { "success": true }` is
   returned. Unknown statuses, non-JSON bodies and unresolvable orders are
   rejected with **400**/**404** and nothing is written.

The full contract (payload v1, retries, idempotency) is documented in
[Webhooks](../webhooks/overview.md) and
[Payload and signature](../webhooks/payload-and-signature.md). The plugin
repository ships a manual webhook smoke checklist (`docs/WEBHOOK-SMOKE.md`) that
covers the signature, a replay with the same `event_id`, an unknown status and the
sandbox gate.

## Status sync (webhook fallback)

Two independent mechanisms keep orders correct when a webhook is delayed or lost:

- **WP-Cron** (`aneepay_sync_pending_orders`) polls `GET /payments/{id}` for up to
  50 `pending`/`on-hold` orders created in the last 7 days, at the configured
  interval, with a 5-minute no-overlap lock. An order older than **Abandoned
  Payment Expiry** is marked **failed** and its stock released — but only once the
  API confirms the payment did not go through; a timeout, a 5xx or a 429 is
  treated as "unknown" and the order is left alone for the next run.
- **Front-end polling** on the order-received page checks the status while the
  customer is still on the site (see [Result pages](#result-pages)).

!!! warning "WP-Cron runs on traffic"

    WP-Cron only fires when someone visits the store. On low-traffic stores,
    schedule a real server cron against `wp-cron.php` or shorten the sync
    interval.

## Test mode

Enable **Test/Sandbox Mode** to send `?sandbox=yes` with every payment request:

- network forced to **Amoy**, token forced to **USDC**;
- `is_safe` check bypassed (payments work while the domain is under review);
- webhooks arrive with `network: "amoy"` and `is_sandbox: true`.

The settings page shows a permanent **SANDBOX** badge and a warning notice while
the mode is on. Turn it off for live payments. See [Sandbox](../sandbox.md).

## Logs

| Log                    | Where                                             | Content                                                                                |
| ---------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Debug log              | WooCommerce → Status → Logs, source `aneepay`     | API requests/responses (opt-in; errors always logged; kept 14 days)                     |
| Request log (settings) | "Request log" button on the gateway settings page | Last 50 calls: time, method, endpoint, code, latency, truncated body — never secrets     |

## Troubleshooting

| Symptom                                                     | Likely cause                                | Fix                                                                                  |
| ----------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------ |
| AneePay missing from checkout                               | Block-based checkout, or gateway disabled   | Use the classic checkout; enable the gateway under Payments                          |
| Settings do not save                                      | Invalid Account ID or empty secret          | Enter a UUID; the secret field must contain a value at least once                    |
| Webhooks return `401`                                       | Wrong or missing Webhook Secret             | Copy the secret from the AneePay account panel ([Webhooks](../webhooks/overview.md)) |
| Order stays pending after payment                           | `status_url` not set, or WP-Cron never runs | Set the account URLs; schedule server-side `wp-cron.php`; or press **Sync a payment** |
| Order pending after a known payment, no webhook ever arrives | The platform does not replay deliveries     | Press **Reconcile payments** for the last N days                                     |
| `403 domain_mismatch`                                       | `Origin` host ≠ account `domain`            | Match the Domain setting to the registered domain (including `www`)                  |
| Gateway shows but payment fails with 403 `account_not_safe` | Domain still under review                   | Wait for review or test with sandbox ([Sandbox](../sandbox.md))                      |

More plugin-specific cases: [Troubleshooting](troubleshooting.md).

## Related sections

- [Custom integration](custom-integration.md) — the same flow without a plugin.
- [Plugin development](plugin-development.md) — how the plugin is built.
- [Troubleshooting](troubleshooting.md) — all platforms.
