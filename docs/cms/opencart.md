# OpenCart 3.x

The **AneePay** payment extension for OpenCart 3.x accepts stablecoin payments
(USDT, USDC, DAI) on Polygon through a hosted checkout and confirms orders by
webhook, with the API polling the fallback when a webhook is lost. This page
covers installation, every setting, checkout and result-page behavior, order
statuses, logging, and test mode.

!!! warning "Beta"

    The CMS plugins are in beta. The payment flow is complete and tested against
    the three stands in the repository, but the admin tooling and this
    documentation are still settling. Read [Beta limitations](limitations-beta.md)
    before taking live payments.

## Requirements

| Component       | Minimum | Notes                                                                     |
| --------------- | ------- | ------------------------------------------------------------------------- |
| OpenCart        | 3.0.x   | Packaged as an `.ocmod.zip`; OpenCart 4 is **not** supported              |
| PHP             | 7.4+    | OpenCart 3 does not run on PHP 8, so 7.4 (or a 7.x release) is required   |
| AneePay account | —       | See [Account setup](../getting-started/account-setup.md)                  |

The extension needs the `curl`, `json` and `openssl` PHP extensions that every
OpenCart 3 store already uses for its payment gateways.

## Installation

1. Download `opencart-aneepay-<version>.ocmod.zip` from the plugin releases.
2. In the store admin: **Extensions → Installer → Upload** the zip. The package
   adds only new files (declared in `install.xml`); it modifies **no** OpenCart
   core files.
    - Alternative: extract the package and copy its `upload/` folder contents into
      the store root.
3. **Extensions → Payments** → find **AneePay** → **Install** → **Edit**.
4. Fill in the settings and save. The extension creates its storage for order
   mappings (`aneepay_order`), the request log (`aneepay_log`) and the webhook
   event log (`aneepay_event`) on install, and upgrades an older table in place
   when the settings page is opened.

## Settings

Settings live at **Extensions → Payments → AneePay → Edit**.

| Field                                       | Required | Purpose                                                                           |
| ------------------------------------------- | -------- | --------------------------------------------------------------------------------- |
| Status                                      | yes      | Enable the payment method.                                                        |
| Title / Description                         | no       | What the customer sees at checkout.                                               |
| Account ID                                  | yes      | Account UUID; settings are rejected unless it is a valid UUID.                    |
| Webhook Secret                              | yes      | Signs `X-AneePay-Signature`. Leaving it blank on re-save keeps the stored value.  |
| Domain                                      | no       | Host sent as `Origin`; empty means "use the store host", never the request host.  |
| Test Mode                                   | no       | Adds `?sandbox=yes` (Amoy + USDC, `is_safe` bypass).                              |
| Cryptocurrency                              | no       | `usdt` (default), `usdc`, `dai`. Ignored in sandbox (always USDC).                |
| Blockchain                                  | no       | `polygon` (default) or `amoy`. Amoy is forced in sandbox.                         |
| Exchange Rate Source                        | no       | **Auto** (ECB from Frankfurter, store rate as fallback) or **manual only**.        |
| Manual Exchange Rate                        | no       | Store-currency units per 1 token; must be positive.                               |
| Order status: pending / paid / failed / cancelled | yes | Which OpenCart order status each payment status maps to (see defaults below).     |
| Abandoned Payment Expiry (minutes)          | no       | Pending orders older than this are closed by the cron job. Default 120; **0 disables**. |
| On uninstall                                | no       | **Keep data** (default) or **Delete data** for stored orders and logs.            |

Order status defaults: **pending = 1 (Pending)**, **paid = 2 (Processing)**,
**failed = 10 (Failed)**, **cancelled = 7 (Cancelled)**. Saving rejects an empty
dropdown or the same status used twice — a failed or cancelled payment must
always leave an order-history entry.

The settings page also shows:

- a **SANDBOX / LIVE** badge;
- a **Test connection** button — calls `GET /accounts/{account_id}/payments`,
  validating the account, the `Origin` domain and `is_safe` without creating a
  payment;
- an **example conversion** preview;
- a **request log** of the last API calls (no secrets), kept for 14 days;
- the copyable store URLs and the cron URL;
- **Sync a payment** — enter an AneePay payment ID (and optionally an order ID)
  to fetch that payment and apply its status right away;
- **Reconcile payments** — read the account's payment list for the last 1–30 days
  and apply the status of every payment that matches an order; it reports
  `checked` / `matched` / `updated` / `unmatched`.

!!! warning "A webhook secret is mandatory"

    Without it every webhook is rejected with `401`, and the order only moves
    forward through the cron job. Copy the secret from the AneePay account panel.

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
2. On confirm the plugin converts the order total from the store currency to
   USD and then to the token, rounding **up** to 2 decimals, and calls
   `POST /payments/` **from the store server** with
   `description: "Order #<order_id>"`.
3. The order moves to the configured **pending** status and the customer is
   redirected to `checkout_url`.
4. The mapping (`payment_id`, `operation_id`, `checkout_url`, amounts, rate
   source, sandbox flag) is stored with the order for later webhook and cron
   reconciliation. The rate and the token amount are fixed at this moment; the
   breakdown shown before is an estimate and says so.
5. On the result page the customer sees the fixed amount to pay for as long as
   the payment is not resolved.

**One payment per order:** a mapping in the `creating` state locks the order
while the payment is created, so a duplicate tab or a double click cannot start a
second AneePay payment. If the API answer is lost (timeout, unreadable body), the
plugin adopts the payment it finds in the account list by amount and order
reference instead of retrying blind. If saving the mapping still fails after the
payment exists, the order is **not** cancelled: the failure is logged with the
payment ID and checkout URL, the order history says it needs attention, and the
buyer is sent to the checkout.

### Result pages

Both `success` and `fail` land on the same page, which resolves the outcome on
the **server** before rendering:

- the plugin calls `GET /payments/{id}` (throttled to one call per order per five
  seconds) and applies the status through the same code path as the webhook;
- **paid** → confirmation with the order number and the amount that was charged;
- **failed** → "payment not completed" and a link back to the checkout. This is
  the only state that offers a retry, so a buyer who actually paid is never sent
  to pay twice;
- **pending** → the amount, the payment ID and the address to pay.

Because the status is fetched on every page load, the page is correct with
JavaScript disabled. JavaScript only adds convenience: while the payment is
pending the page polls the status after 5 seconds, then 15, then every 30
seconds for at most 30 minutes. After that the automatic checks pause and an
explicit **Check again** button appears, which restarts the budget. The
**"I already paid"** button also triggers an immediate check.

The polling endpoint accepts only the order started in this browser session and
is rate-limited.

!!! note "Result page needs the signed cookie"

    The result page identifies the order through a signed cookie that lives for 24
    hours and is renewed on every view (at most once a minute). A buyer who pays
    from a wallet app and comes back much later sees the page without an order
    number instead of a confirmation — open the order in the admin to see its
    state.

## Order statuses

| Payment status | OpenCart effect                                                       |
| -------------- | --------------------------------------------------------------------- |
| `pending`      | Order → configured **pending** status (default 1)                     |
| `success`      | Order → configured **paid** status (default 2); **terminal, never downgraded** |
| `failed`       | Order → configured **failed** status (default 10); stock restored once |
| `cancelled`    | Order → configured **cancelled** status (default 7); stock restored once |

Notes:

- The payment status is always recorded on the order mapping, even if a status
  dropdown were left empty.
- Applying the same status twice is a no-op; unknown statuses are ignored.
- Stock is restored exactly once (a one-time marker on the mapping) and only when
  the order leaves a status that reserves stock — OpenCart's own handling covers
  the case where it restocks by itself.
- An order that reaches `success` is never moved backwards by a later webhook or
  cron run.

## Webhook

```text
POST https://<store>/index.php?route=extension/payment/aneepay/callback
```

Processing:

1. **Signature verified first** (fail-closed): `X-AneePay-Signature` must be the
   HMAC-SHA256 of the raw body keyed with the Webhook Secret. Missing secret,
   missing header or mismatch → **401**, nothing is processed.
2. The delivery is deduplicated by `event_id` (or `sha256(body)` for legacy
   payloads). A retry returns `200 { "success": true, "duplicate": true }` and
   changes nothing; entries are pruned after 7 days.
3. `operation_id` is parsed as a 128-bit integer string (never a float).
4. `timestamp` is informational: it must be present and numeric when the payload
   carries `version`/`event_id`, but there is **no** freshness window — the
   signature is the authorisation, and replays are rejected by the dedup above.
5. The status must be one of `pending|success|failed|cancelled`; anything else is
   **400**.
6. The order is resolved by `payment_id` → `operation_id` → `operation_id`
   decoded back to the payment UUID → `description: "Order #N"`. Only orders that
   have an AneePay mapping qualify; an unresolvable order is **404** and is not
   recorded.
7. A sandbox payment never completes a live order and vice versa: a mismatch
   answers `200 { "success": false, "ignored": "sandbox_mismatch" }` and is logged.
8. The status is applied idempotently, the order history gets the note, and the
   response is `200 { "success": true, "status": "…" }`. A failure while applying
   answers **500** and releases the dedup claim so the vendor's retry is accepted.

Contract details: [Webhooks](../webhooks/overview.md),
[Payload and signature](../webhooks/payload-and-signature.md).

## Status sync (cron fallback)

OpenCart has no built-in scheduler, so the extension exposes a polling endpoint
and you schedule it yourself:

```text
https://<store>/index.php?route=extension/payment/aneepay/cron&secret=<cron_secret>
```

- The **secret is generated automatically** on the first settings-page visit and
  shown next to the URL. It is compared with `hash_equals`; requests without the
  exact secret get **403**.
- Add the URL to your server crontab at whatever interval suits you — OpenCart
  has no scheduler of its own, so this entry is the only thing that decides how
  often pending orders are polled. Every 5 minutes is a sensible default:
  `*/5 * * * * curl -s '<cron-url>' >/dev/null`.
- Each run takes the **oldest 100** pending orders no older than **7 days** and
  calls `GET /payments/{id}` for each, applying the answer through the same code
  path as the webhook.
- A **300-second lock** prevents overlapping runs, and the request log and event
  log are pruned on every run.
- **Abandoned payments:** an order older than *Abandoned Payment Expiry*
  (default 120 minutes) is moved to the configured **cancelled** status — or to
  **failed** when no cancelled status is configured — but only once the API
  confirms the payment did not go through. A timeout, a 5xx answer or a `429`
  leaves the order untouched for the next run. Set the value to `0` to disable
  expiry entirely.
- The endpoint answers with JSON counters: `checked`, `updated`, `expired`,
  `failed`.

## Test mode

Enable **Test Mode** to send `?sandbox=yes` with every payment request:

- network forced to **Amoy**, token forced to **USDC**;
- the `is_safe` check is bypassed;
- webhooks arrive with `network: "amoy"` and `is_sandbox: true`.

The settings page shows a **SANDBOX** badge while the mode is on. Turn it off for
live payments. See [Sandbox](../sandbox.md).

## Logs

| Log             | Table           | Content                                                    | Retention |
| --------------- | --------------- | ---------------------------------------------------------- | --------- |
| Request log     | `aneepay_log`   | Method, endpoint, response code, latency, truncated body    | 14 days   |
| Webhook events  | `aneepay_event` | One row per accepted delivery, used for the dedup           | 7 days    |

Secrets are never written to either table. Older entries are deleted
automatically, so no maintenance is required.

## Data and uninstall

| Data                    | Content                                                    |
| ----------------------- | ---------------------------------------------------------- |
| Order ↔ payment mapping | Amounts, rate source, sandbox flag, one-time restock marker |
| Request log             | Entries for each API, webhook and cron call                |
| Webhook event log       | Delivery ids used to ignore retries                        |

Uninstall **keeps all three** by default; choose **Delete data** in the settings
before uninstalling to drop them. Opening the settings page after an upgrade
migrates the storage in place — no manual SQL.

If you rotate the cron secret, the stored URL stops working until you update your
scheduler; requests carrying an old secret are rejected with `403`.

## Troubleshooting

| Symptom                                       | Likely cause                                                              | Fix                                                            |
| --------------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Extension missing after upload                | Zip not installed with **Extensions → Installer**, or `upload/` not copied | Re-upload the `.ocmod.zip`, then Install the payment extension  |
| Settings do not save                        | Invalid Account ID, empty secret, or the same order status picked twice   | Enter a UUID; keep the secret non-empty; pick four distinct statuses |
| Webhooks return `401`                         | Wrong or missing Webhook Secret                                           | Copy the secret from the AneePay account panel                 |
| Webhook returns `400`                         | Non-JSON body, unknown `status`, or a missing/non-numeric `timestamp`     | Send the documented payload; do not reformat the body           |
| Order stays pending though paid               | `status_url` not set in the account panel, or cron not scheduled          | Set the account URLs; schedule the cron URL in crontab          |
| A webhook was lost for good                   | The platform delivers each event once and never replays it                | Use **Reconcile payments** on the settings page                 |
| Cron returns `403`                            | Missing or wrong `secret` parameter                                       | Use the exact cron URL from the settings page                   |
| Cron reports `failed` > 0                     | The account or the `Origin` domain was rejected by the API                | Check the request log, then the Domain setting                  |
| `403 domain_mismatch`                         | `Origin` host ≠ account `domain`                                          | Match the Domain setting to the registered domain               |

More cases: [Troubleshooting](troubleshooting.md).

## Related sections

- [Custom integration](custom-integration.md) — the same flow without a plugin.
- [Plugin development](plugin-development.md) — how the plugin is built.
- [Troubleshooting](troubleshooting.md) — all platforms.
