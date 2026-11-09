# OpenCart 3.x

The **AneePay** payment extension for OpenCart 3.x accepts stablecoin payments
(USDT, USDC, DAI) on Polygon through hosted checkout and confirms orders by
webhook. This page covers installation, settings, checkout behavior, order
statuses, and test mode.

## Requirements

| Component       | Minimum | Notes                                                    |
| --------------- | ------- | -------------------------------------------------------- |
| OpenCart        | 3.x     | Extension is packaged as an `.ocmod.zip`                 |
| PHP             | 7.4+    | —                                                        |
| AneePay account | —       | See [Account setup](../getting-started/account-setup.md) |

## Installation

1. Download `aneepay-<version>.ocmod.zip` from the plugin releases.
2. In the store admin: **Extensions → Installer → Upload** the zip. The package
   contains only new files (declared in `install.xml`); it modifies **no** OpenCart
   core files.
   - Alternative: extract the package and copy its `upload/` folder contents into
     the store root.
3. **Extensions → Payments** → find **AneePay** → **Install** → **Edit**.
4. Fill in the settings and save. The extension creates its own storage for
   order mappings and request logs on install and upgrades it automatically when
   the settings page is opened.

## Settings

Settings live at **Extensions → Payments → AneePay → Edit**.

| Field                                       | Required | Purpose                                                                          |
| ------------------------------------------- | -------- | -------------------------------------------------------------------------------- |
| Status                                      | yes      | Enable the payment method.                                                       |
| Title / Description                         | no       | What the customer sees at checkout.                                              |
| Account ID                                  | yes      | Account UUID; must be a valid UUID or settings are rejected.                     |
| Webhook Secret                              | yes      | Signs `X-AneePay-Signature`. Leaving it blank on re-save keeps the stored value. |
| Domain                                      | no       | Host sent as `Origin`; empty means "use the store host".                         |
| Test Mode                                   | no       | Adds `?sandbox=yes` (Amoy + USDC, `is_safe` bypass).                             |
| Cryptocurrency                              | no       | `usdt` (default), `usdc`, `dai`. Ignored in sandbox (always USDC).               |
| Blockchain                                  | no       | `polygon` (default) or `amoy`. Amoy is forced in sandbox.                        |
| Exchange Rate Source                        | no       | **Auto** (Frankfurter/ECB with store-rate fallback) or **manual only**.          |
| Manual Exchange Rate                        | no       | Store-currency units per 1 token; must be positive.                              |
| Order status: pending/paid/failed/cancelled | yes      | Which OpenCart order status each payment status maps to.                         |
| Status sync (cron) interval                 | no       | Expected polling cadence for the cron endpoint (5/10/15/30 minutes).             |
| On uninstall                                | no       | **Keep data** (default) or **Delete data** for stored orders and logs.           |

The settings page also shows:

- a **SANDBOX / LIVE** badge;
- a **Test connection** button — calls `GET /accounts/{account_id}/payments`,
  validating the account, the `Origin` domain, and `is_safe` without creating a
  payment;
- an **example conversion** preview;
- a **request log** (last API calls, no secrets);
- the copyable store URLs below.

!!! warning "Map all four order statuses"

    Only `pending` and `paid` have defaults (status IDs 1 and 2). **Failed and
    cancelled default to "no status"**: the payment status is still recorded, but
    the order will not change status. Configure all four dropdowns.

## Store URLs for the account panel

Copy these from the settings page into the AneePay account panel:

| Account field  | Store URL                                                            |
| -------------- | -------------------------------------------------------------------- |
| `status_url`   | `https://<store>/index.php?route=extension/payment/aneepay/callback` |
| `success_url`  | `https://<store>/index.php?route=extension/payment/aneepay/success`  |
| `fail_url`     | `https://<store>/index.php?route=extension/payment/aneepay/fail`     |

Additionally, the settings page shows a **cron URL** (see
[Status sync](#status-sync-cron-fallback)).

## Checkout

1. The customer selects AneePay on the checkout confirmation page; the payment
   method card shows the conversion breakdown ("You will pay X TOKEN").
2. On confirm the plugin converts the order total (store currency → USD → token,
   rounded **up** to 2 decimals) and calls `POST /payments/` **from the store
   server** with `description: "Order #<order_id>"`.
3. The order moves to the configured **pending** status and the customer is
   redirected to `checkout_url`.
4. The mapping (`payment_id`, `operation_id`, `checkout_url`, amounts, rate
   source) is stored with the order for later webhook and cron reconciliation.
5. On the result page the customer can press **"I already paid"**, which polls the
   status (the endpoint only accepts the order started in this browser session and
   is rate-limited).

**Idempotency:** if the order already has a pending AneePay payment, confirm
reuses its `checkout_url` instead of creating a second payment. If payment
creation fails, the order is left untouched and the customer returns to checkout
with the error message.

## Order statuses

| Payment status | OpenCart effect                                                        |
| -------------- | ---------------------------------------------------------------------- |
| `pending`      | Order → configured **pending** status                                  |
| `success`      | Order → configured **paid** status; **terminal, never downgraded**     |
| `failed`       | Order → configured **failed** status (if set); stock restored once     |
| `cancelled`    | Order → configured **cancelled** status (if set); stock restored once  |

Notes:

- The plugin always records the payment status on the order, even when the order
  status dropdown maps to "no status".
- Applying the same status twice is a no-op; unknown statuses are ignored.
- Stock restoration runs exactly once (a one-time marker on the order) and only
  when the order leaves a stock-reserving status.

## Webhook

```text
POST https://<store>/index.php?route=extension/payment/aneepay/callback
```

Processing:

1. **Signature verified first** (fail-closed): `X-AneePay-Signature` must be the
   HMAC-SHA256 of the raw body keyed with the Webhook Secret. Missing secret,
   missing header, or mismatch → **401**, nothing is processed.
2. `operation_id` is parsed as a 128-bit integer string (never a float).
3. The `timestamp` must be fresher than 24 hours (replay guard), otherwise
   **400**.
4. The order is resolved by `payment_id` → `operation_id` → `operation_id`
   decoded back to the payment UUID → `description: "Order #N"` (only orders that
   have an AneePay mapping qualify).
5. The status is applied idempotently; the response is
   `200 { "success": true, "status": "…" }`.

Contract details: [Webhooks](../webhooks/overview.md),
[Payload and signature](../webhooks/payload-and-signature.md).

## Status sync (cron fallback)

OpenCart has no built-in scheduler, so the extension exposes a polling endpoint
and you schedule it yourself:

```text
https://<store>/index.php?route=extension/payment/aneepay/cron&secret=<cron_secret>
```

- The **secret is generated automatically** on the first settings-page visit and
  shown next to the URL. Requests without the exact secret get **403**.
- Add the URL to your server crontab at the configured interval, e.g.
  `*/5 * * * * curl -s '<cron-url>' >/dev/null`.
- The endpoint polls `GET /payments/{id}` for pending orders and applies the
  result through the same code path as the webhook; a 5-minute lock prevents
  overlapping runs.

## Test mode

Enable **Test Mode** to send `?sandbox=yes` with every payment request:

- network forced to **Amoy**, token forced to **USDC**;
- `is_safe` check bypassed;
- webhooks arrive with `network: "amoy"` and `is_sandbox: true`.

The settings page shows a **SANDBOX** badge while the mode is on. Turn it off for
live payments. See [Sandbox](../sandbox.md).

## Data and uninstall

| Data                    | Content                                                      |
| ----------------------- | ------------------------------------------------------------ |
| Order ↔ payment mapping | Amounts, rate source, one-time restock marker                |
| Request log             | Entries for each API, webhook, and cron call                 |

Uninstall **keeps both** by default; choose **Delete data** in the settings
before uninstalling to drop them. Opening the settings page after an upgrade
migrates the storage in place — no manual SQL.

If you rotate the cron secret, the stored URL keeps working until you update your
scheduler; requests carrying an old secret are rejected with `403`.

## Troubleshooting

| Symptom                                       | Likely cause                                                              | Fix                                                            |
| --------------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Extension missing after upload                | Zip not installed via **Extensions → Installer**, or `upload/` not copied | Re-upload the `.ocmod.zip`, then Install the payment extension |
| Settings will not save                        | Invalid Account ID or empty secret                                        | Enter a UUID; keep the secret field non-empty at least once    |
| Webhooks return `401`                         | Wrong or missing Webhook Secret                                           | Copy the secret from the AneePay account panel                 |
| Order stays pending though paid               | `status_url` not set in the account panel, or cron not scheduled          | Set the account URLs; schedule the cron URL in crontab         |
| `failed` / `cancelled` never change the order | Status mapping defaults to "no status"                                    | Map all four statuses in the settings                          |
| Cron returns `403`                            | Missing or wrong `secret` parameter                                       | Use the exact cron URL from the settings page                  |
| `403 domain_mismatch`                         | `Origin` host ≠ account `domain`                                          | Match the Domain setting to the registered domain              |

More cases: [Troubleshooting](troubleshooting.md).

## Related sections

- [Custom integration](custom-integration.md) — the same flow without a plugin.
- [Plugin development](plugin-development.md) — how the plugin is built.
- [Troubleshooting](troubleshooting.md) — all platforms.
