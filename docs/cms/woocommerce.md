# WooCommerce

The **AneePay Crypto Gateway for WooCommerce** plugin accepts stablecoin payments
(USDT, USDC, DAI) on Polygon through hosted checkout and confirms orders by
webhook. This page covers installation, settings, checkout behavior, order
statuses, and test mode.

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

1. Download `aneepay.zip` from the plugin releases.
2. In WordPress admin: **Plugins → Add New Plugin → Upload Plugin** → select the
   zip → **Install Now** → **Activate**.
3. WooCommerce must already be installed and active. If it is not, the plugin shows
   an admin notice and deactivates itself.
4. Open **WooCommerce → Settings → Payments**, enable **AneePay Crypto**, then
   click **Manage** (or **Set up**).

## Settings

Settings live at **WooCommerce → Settings → Payments → AneePay Crypto**.

| Field                | Required | Purpose                                                                                 |
| -------------------- | -------- | --------------------------------------------------------------------------------------- |
| Enable/Disable       | yes      | Master switch for the payment method.                                                   |
| Title / Description  | no       | What the customer sees on the payment method card.                                      |
| Account ID           | yes      | Account UUID; must be a valid UUID or settings are rejected.                            |
| Webhook Secret       | yes      | Signs `X-AneePay-Signature`. Leaving the field blank on re-save keeps the stored value. |
| Domain               | no       | Host sent as `Origin`; empty means "use the site host".                                 |
| Test/Sandbox Mode    | no       | Adds `?sandbox=yes` to API calls (Amoy + USDC, `is_safe` bypass).                       |
| Cryptocurrency       | no       | `usdt` (default), `usdc`, `dai`. Ignored in sandbox (always USDC).                      |
| Blockchain           | no       | `polygon` (default) or `amoy`. Amoy is forced in sandbox.                               |
| Exchange Rate Source | no       | **Auto** (Frankfurter/ECB with manual fallback) or **manual rate only**.                |
| Manual Exchange Rate | no       | Store-currency units per 1 token (≈ 1 USD); must be positive.                           |
| Debug Log            | no       | Logs API calls to **WooCommerce → Status → Logs** (source `aneepay`).                   |
| Status Sync Interval | no       | WP-Cron polling of pending orders: every 5 (default) / 10 / 15 / 30 minutes.            |

The settings page also provides:

- a **SANDBOX / LIVE** badge with the active token and network;
- a **Quick setup** card listing the exact URLs to paste into the AneePay panel;
- a **Test connection** button — it calls
  `GET /accounts/{account_id}/payments`, which validates the account, the `Origin`
  domain, and `is_safe` without creating a payment;
- an **example conversion** preview for the current rate settings;
- a **Request log** panel with the last 50 API calls (never contains secrets).

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
   "You will pay X TOKEN".
3. The plugin calls `POST /payments/` **from the store server** with
   `X-Account-Id`, `Origin`, and `description: "Order #<number>"`, then redirects
   the customer to `checkout_url`.
4. The order is set to **pending** with a note containing the AneePay payment ID,
   and product stock is reduced.
5. While payment is pending, the thank-you and order-pay pages poll the status
   automatically (a "Checking…" indicator), and the page re-syncs from the API
   before rendering the result.

**Idempotency:** if an order already has a pending AneePay payment, a reload or
double click reuses the existing `checkout_url` instead of creating a second
payment.

**Result pages:** `/?aneepay=success` and `/?aneepay=fail` identify the order from
a signed, one-hour cookie set at checkout; an invalid or expired cookie shows the
page without order details. The page pulls the current status from the API, so a
webhook that arrived during the redirect is reflected correctly.

!!! note "Block-based checkout"

    The plugin integrates with the classic checkout. If your store uses the
    block-based Cart/Checkout blocks and AneePay does not appear, switch that page
    to the classic checkout shortcode.

## Order statuses

| Payment status | WooCommerce effect                                                                         |
| -------------- | ------------------------------------------------------------------------------------------ |
| `pending`      | Order stays **pending**; note: "Awaiting crypto payment…"                                  |
| `success`      | `payment_complete()` — order moves to processing/completed; **terminal, never downgraded** |
| `failed`       | Order → **failed**; reserved stock is restored exactly once                                |
| `cancelled`    | Order → **cancelled**; reserved stock is restored exactly once                             |

Notes:

- The payment status is stored on the order as `_aneepay_payment_status`;
  `_aneepay_payment_id` and `_aneepay_operation_id` link the order to the API
  record.
- Applying the same status twice is a no-op, so redelivered webhooks are harmless.
- Unknown statuses are ignored.

## Webhook

The plugin registers a public REST route:

```text
POST /wp-json/aneepay/v1/webhook
```

Processing:

1. **Signature is verified first** (fail-closed): `X-AneePay-Signature` must be
   the HMAC-SHA256 of the raw body keyed with `Webhook Secret`. Missing secret,
   missing header, or mismatch → **401**, nothing is processed.
2. `operation_id` is decoded as a 128-bit integer string (never as a float).
3. The `timestamp` must be fresher than 24 hours (replay guard), otherwise
   **400**.
4. The order is resolved in this order: `order_id` → `payment_id` →
   `operation_id` → `operation_id` decoded back to the payment UUID →
   `description: "Order #N"`. Only orders paid with this gateway qualify.
5. The status is applied idempotently; a matching `200 { "success": true }` is
   returned.

The full contract (payload v1, retries, idempotency) is documented in
[Webhooks](../webhooks/overview.md) and
[Payload and signature](../webhooks/payload-and-signature.md).

## Status sync (webhook fallback)

Two independent mechanisms keep orders correct when a webhook is delayed or lost:

- **WP-Cron** (`aneepay_sync_pending_orders`) polls `GET /payments/{id}` for up to
  20 `pending`/`on-hold` orders at the configured interval, with a no-overlap lock.
- **Front-end polling** on the thank-you / order-pay page checks the status when
  the customer is still on the site. The endpoint requires the order key (or the
  owning customer), so another visitor cannot poll or advance your order.

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

| Log                    | Where                                             | Content                                                           |
| ---------------------- | ------------------------------------------------- | ----------------------------------------------------------------- |
| Debug log              | WooCommerce → Status → Logs, source `aneepay`     | API requests/responses (opt-in)                                   |
| Request log (settings) | "Request log" button on the gateway settings page | Last 50 calls: time, method, endpoint, code, latency — no secrets |

## Troubleshooting

| Symptom                                                     | Likely cause                                | Fix                                                                                  |
| ----------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------ |
| AneePay missing from checkout                               | Block-based checkout, or gateway disabled   | Use the classic checkout; enable the gateway under Payments                          |
| Settings will not save                                      | Invalid Account ID or empty secret          | Enter a UUID; the secret field must contain a value at least once                    |
| Webhooks return `401`                                       | Wrong or missing Webhook Secret             | Copy the secret from the AneePay account panel ([Webhooks](../webhooks/overview.md)) |
| Order stays pending after payment                           | `status_url` not set, or WP-Cron never runs | Set the account URLs; schedule server-side `wp-cron.php`                             |
| `403 domain_mismatch`                                       | `Origin` host ≠ account `domain`            | Match the Domain setting to the registered domain (including `www`)                  |
| Gateway shows but payment fails with 403 `account_not_safe` | Domain still under review                   | Wait for review or test with sandbox ([Sandbox](../sandbox.md))                      |

More plugin-specific cases: [Troubleshooting](troubleshooting.md).

## Related sections

- [Custom integration](custom-integration.md) — the same flow without a plugin.
- [Plugin development](plugin-development.md) — how the plugin is built.
- [Troubleshooting](troubleshooting.md) — all platforms.
