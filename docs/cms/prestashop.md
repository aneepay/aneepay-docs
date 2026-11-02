# PrestaShop 1.7 / 8

The **AneePay Crypto Gateway** module (`ps_aneepay`) accepts stablecoin payments
(USDT, USDC, DAI) on Polygon through hosted checkout and confirms orders by
webhook. This page covers installation, settings, checkout behavior, order
states, and test mode.

## Requirements

| Component       | Minimum     | Notes                                                    |
| --------------- | ----------- | -------------------------------------------------------- |
| PrestaShop      | 1.7.0 – 8.x | Declared by the module compliancy check                  |
| PHP             | 7.4+        | —                                                        |
| AneePay account | —           | See [Account setup](../getting-started/account-setup.md) |

## Installation

1. Download `ps_aneepay.zip` from the plugin releases.
2. In the store admin: **Modules → Module manager → Upload a module** → select
   the zip → **Install**.
3. Click **Configure** on the module. Installation creates the module's storage
   for order mappings and request logs, plus the default configuration.

!!! warning "Sandbox is enabled on a fresh install"

    The module installs with **Test Mode ON** (`ANEEPAY_TEST_MODE = 1`), so new
    payments are created on Amoy with USDC until you turn it off. Disable
    **Test Mode** before accepting live payments.

## Settings

Settings live at **Modules → Module manager → AneePay Crypto Gateway → Configure**.

| Field                                            | Required | Purpose                                                                          |
| ------------------------------------------------ | -------- | -------------------------------------------------------------------------------- |
| Account ID                                       | yes      | Account UUID; sent as `X-Account-Id`.                                            |
| Webhook Secret                                   | yes      | Signs `X-AneePay-Signature`. Leaving it blank on re-save keeps the stored value. |
| Domain                                           | no       | Host sent as `Origin`; empty means "use the shop host" (always sent).            |
| Test Mode                                        | no       | Adds `?sandbox=yes` (Amoy + USDC, `is_safe` bypass). **On by default.**          |
| Cryptocurrency                                   | no       | `usdt` (default), `usdc`, `dai`. Ignored in sandbox (always USDC).               |
| Blockchain                                       | no       | `polygon` (default) or `amoy`. Amoy is forced in sandbox.                        |
| Exchange Rate Source                             | no       | **Auto** (Frankfurter/ECB with shop-rate fallback) or **manual only**.           |
| Manual Exchange Rate                             | no       | Shop-currency units per 1 token; must be positive.                               |
| Order state: pending / paid / failed / cancelled | yes      | Which PrestaShop order state each payment status maps to.                        |
| Keep data on uninstall                           | no       | Default **on**: stored orders and logs survive uninstall.                        |

Default order states (PrestaShop's own values):

| Payment status | Default state              |
| -------------- | -------------------------- |
| `pending`      | Awaiting payment           |
| `success`      | Payment accepted           |
| `failed`       | Payment error              |
| `cancelled`    | Payment canceled           |

The settings page also shows:

- a **SANDBOX / LIVE** badge;
- a **Test connection** button — calls `GET /accounts/{account_id}/payments`,
  validating the account, the `Origin` domain, and `is_safe` without creating a
  payment;
- an **offline conversion preview** for the current rate settings;
- a **request log** panel (last API calls, no secrets);
- the copyable store URLs below.

## Store URLs for the account panel

Copy these from the settings page into the AneePay account panel:

| Account field  | Store URL                                                                  |
| -------------- | -------------------------------------------------------------------------- |
| `status_url`   | `https://<store>/index.php?fc=module&module=ps_aneepay&controller=webhook` |
| `success_url`  | `https://<store>/index.php?fc=module&module=ps_aneepay&controller=success` |
| `fail_url`     | `https://<store>/index.php?fc=module&module=ps_aneepay&controller=fail`    |

Additionally, the settings page shows a **cron URL** (see
[Status sync](#status-sync-cron-fallback)).

## Checkout

1. The customer selects AneePay; the payment option shows the conversion
   breakdown ("You will pay X TOKEN").
2. The module creates the **order first** in the configured pending state
   (`validateOrder()`), then converts the order total (shop currency → USD →
   token, rounded **up** to 2 decimals) and calls `POST /payments/` **from the
   shop server** with `description: "Order #<order_id>"`.
3. If payment creation fails, the order is moved to the cancelled state, reserved
   stock is released, and the customer returns to the shop with the error — no
   orphan payment is left behind.
4. On success the mapping (`payment_id`, `operation_id`, `checkout_url`, amounts,
   rate source) is stored with the order, and the customer sees a pending screen
   with the hosted-checkout link.
5. The customer can press **"I already paid"** on that screen, which polls the
   status through the module's `check` controller.

**Idempotency:** if the cart (or the order from the fail page) already has a
pending AneePay payment, the module reuses it instead of creating a duplicate
order and payment.

## Order states

| Payment status | PrestaShop effect                                                   |
| -------------- | ------------------------------------------------------------------- |
| `pending`      | Order created in the configured **pending** state                   |
| `success`      | Order → configured **paid** state; **terminal, never downgraded**   |
| `failed`       | Order → configured **failed** state; stock restored once            |
| `cancelled`    | Order → configured **cancelled** state; stock restored once         |

Notes:

- The payment status is always recorded on the order, even if a status mapping
  is left at "no state".
- Applying the same status twice is a no-op; unknown statuses are ignored.
- Stock restoration is guarded by a one-time marker on the order and runs once.

## Webhook

```text
POST https://<store>/index.php?fc=module&module=ps_aneepay&controller=webhook
```

Processing:

1. **Signature verified first** (fail-closed): `X-AneePay-Signature` must be the
   HMAC-SHA256 of the raw body keyed with the Webhook Secret. Missing secret,
   missing header, or mismatch → **401**, nothing is processed.
2. `operation_id` is parsed as a 128-bit integer string (never a float).
3. The `timestamp` must be fresher than 24 hours (replay guard), otherwise
   **400**.
4. The order is resolved by `payment_id` → `operation_id` → `operation_id`
   decoded back to the payment UUID → `#N` from the description (only orders with
   an AneePay mapping qualify).
5. The status is applied idempotently through the order history; the response is
   `200 { "success": true, "status": "…" }`.

Contract details: [Webhooks](../webhooks/overview.md),
[Payload and signature](../webhooks/payload-and-signature.md).

## Status sync (cron fallback)

PrestaShop has no built-in scheduler, so the module exposes a polling endpoint
that you schedule yourself:

```text
https://<store>/index.php?fc=module&module=ps_aneepay&controller=cron&secret=<cron_secret>
```

- The **secret is generated once** and shown next to the cron URL on the
  settings page. Requests without it are refused (**403**).
- Add the URL to your server crontab at the configured interval, e.g.
  `*/5 * * * * curl -s '<cron-url>' >/dev/null`.
- The endpoint polls `GET /payments/{id}` for pending orders and applies the
  result through the same code path as the webhook.

## Test mode

With **Test Mode** on, every payment request carries `?sandbox=yes`:

- network forced to **Amoy**, token forced to **USDC**;
- `is_safe` check bypassed;
- webhooks arrive with `network: "amoy"` and `is_sandbox: true`.

The settings page shows a **SANDBOX** badge while the mode is on. Remember it is
**on by default** after installation. See [Sandbox](../sandbox.md).

## Data, upgrades, and uninstall

| Data                    | Content                                                 |
| ----------------------- | ------------------------------------------------------- |
| Order ↔ payment mapping | Amounts, rate source, one-time restock marker           |
| Request log             | Entries for each API, webhook, and cron call            |

- Uninstall keeps both by default; disable **Keep data on uninstall** to drop
  them.
- Upgrading from 1.1.x runs an automatic upgrade script that adds the restock
  marker — no manual SQL.

## Troubleshooting

| Symptom                                | Likely cause                                                     | Fix                                                           |
| -------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------- |
| Module will not install                | Zip uploaded as a folder, or unsupported PrestaShop version      | Upload `ps_aneepay.zip` via **Upload a module**; use PS 1.7/8 |
| New payments go to the network testnet | **Test Mode is on by default**                                   | Disable Test Mode for live payments                           |
| Settings will not save                 | Empty Account ID or secret                                       | Enter the UUID and the secret from the account panel          |
| Webhooks return `401`                  | Wrong or missing Webhook Secret                                  | Copy the secret from the AneePay account panel                |
| Order stays pending though paid        | `status_url` not set in the account panel, or cron not scheduled | Set the account URLs; schedule the cron URL in crontab        |
| Cron returns `403`                     | Missing or wrong `secret` parameter                              | Use the exact cron URL from the settings page                 |
| `403 domain_mismatch`                  | `Origin` host ≠ account `domain`                                 | Match the Domain setting to the registered domain             |

More cases: [Troubleshooting](troubleshooting.md).

## Related sections

- [Custom integration](custom-integration.md) — the same flow without a plugin.
- [Plugin development](plugin-development.md) — how the plugin is built.
- [Troubleshooting](troubleshooting.md) — all platforms.
