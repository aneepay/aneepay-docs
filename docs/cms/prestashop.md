# PrestaShop 1.7 / 8.x

The `ps_aneepay` module adds AneePay to a PrestaShop checkout: the customer pays
with USDT, USDC or DAI on Polygon, the module redirects them to the hosted
AneePay checkout, and the order is confirmed by a signed webhook — or, when the
webhook never arrives, by the module's own status polling.

!!! warning "Beta"

    The CMS plugins are in beta. The payment flow is complete and tested against
    the three stands in the repository, but the admin tooling and this
    documentation are still settling. Read [Beta limitations](limitations-beta.md)
    before taking live payments.

## Requirements

| Requirement      | Value                                                       |
| ---------------- | ----------------------------------------------------------- |
| PrestaShop       | 1.7.0 or newer, 8.x supported (tested on 8.1.7)              |
| PHP              | 7.4 or newer                                                |
| AneePay account  | with a verified merchant domain, see [Account setup](../getting-started/account-setup.md) |
| Store currency   | any, see [exchange rates](#exchange-rates)                   |

The module ships English translations only.

## Installation

1. Download `prestashop-aneepay-<version>.zip` from the release page.
2. In the back office open **Modules → Module manager** and click
   **Upload a module**.
3. Drop the archive in, or pick it from disk. PrestaShop installs and enables
   the module.
4. Open **Modules → Module manager → AneePay → Configure** and fill in the
   settings below.

!!! warning "Test mode is on by default"

    A freshly installed module runs in sandbox — Amoy, USDC, no real funds. Turn
    test mode off only after the store domain is verified in the AneePay panel.

## Settings

| Setting                    | What it does                                                                                         |
| -------------------------- | ---------------------------------------------------------------------------------------------------- |
| Account ID                 | Your AneePay account UUID. It is sent as `X-Account-Id` on every API call.                             |
| Webhook Secret             | The secret from the AneePay panel. Every webhook is verified with HMAC-SHA256 against it. Mandatory.   |
| Domain                     | Your verified merchant domain, sent as the `Origin` header. Enter a bare host, for example `shop.example.com`. Leave empty to use the shop domain from the PrestaShop configuration — the request host is never used. |
| Test mode                  | Sandbox on/off. **On by default.** Sandbox forces USDC on Amoy.                                        |
| Cryptocurrency             | `USDT`, `USDC` or `DAI`.                                                                              |
| Blockchain                 | `Polygon` for live payments, `Amoy` for test mode.                                                     |
| Exchange Rate Source       | `Auto` (ECB via Frankfurter) or `Manual`.                                                              |
| Manual Exchange Rate       | Used when the source is manual, or as the last fallback. Store currency per 1 USD.                      |
| Order states               | Which local state each payment status maps to, see [Order statuses](#order-statuses).                   |
| Abandoned Payment Expiry   | Minutes before a pending order is closed by the cron job. `0` disables expiry. Default `120`.           |
| Debug log                  | Log every AneePay request and response (kept for 14 days). Errors are always logged.                    |
| Keep data on uninstall     | Keep the `ps_aneepay_order` and `ps_aneepay_log` tables when the module is uninstalled. On by default.  |

The settings page also provides:

- a **SANDBOX / LIVE** badge, so the current mode is visible without opening a
  select;
- a **Test connection** button, which calls `GET /accounts/{id}/payments` and
  reports the HTTP status and the number of payments returned;
- an offline conversion preview: what the current rate would charge for a
  sample amount;
- the request log — the last 50 AneePay calls with method, endpoint, status,
  latency and a truncated body;
- the STATUS, SUCCESS, FAIL and cron URLs, ready to copy into the AneePay panel
  and your crontab;
- **Sync a payment** — paste an AneePay payment ID, optionally an order ID, and
  the module fetches that payment and applies its status immediately;
- **Reconcile payments** — scan the account payment list for the last 1–30 days
  and apply the status of every payment that matches an order. It reports
  `checked`, `matched`, `updated` and `unmatched` counts.

!!! warning "A webhook secret is mandatory"

    With an empty secret every delivery is rejected with `401` — the module
    never applies an unsigned status change. Webhooks are the only way a
    `success` reaches the shop, so without the secret orders stay pending.

## Store URLs for the account panel

| Field      | URL                                                                     |
| ---------- | ----------------------------------------------------------------------- |
| Status     | `https://shop.example.com/index.php?fc=module&module=ps_aneepay&controller=webhook` |
| Success    | `https://shop.example.com/index.php?fc=module&module=ps_aneepay&controller=success` |
| Fail       | `https://shop.example.com/index.php?fc=module&module=ps_aneepay&controller=fail`    |

Status polling runs from your own crontab — PrestaShop has no scheduler of its
own:

```cron
*/5 * * * * curl -fsS "https://shop.example.com/index.php?fc=module&module=ps_aneepay&controller=cron&secret=<cron_secret>" > /dev/null
```

The secret is shown on the settings page. A wrong or missing `secret` answers
`403` and touches nothing.

## Checkout

1. The customer picks AneePay and confirms the order.
2. PrestaShop creates the order in the **pending** state and stores a mapping row
   in `ps_aneepay_order`.
3. The module creates the AneePay payment and redirects the browser to the
   hosted checkout.
4. The customer pays on chain and is redirected back to the **success** or
   **fail** page — both are reached from AneePay, so neither trusts the URL.
5. The webhook (or the cron job) applies the final status.

The amount shown in the shop is an estimate: the store total is converted to USD
and then to the token at the rate frozen when the payment was created, rounded
up. The checkout page says so, and the result page shows the exact amount that
was charged.

Order creation is protected twice. The payment action carries a one-time,
cart-bound token that `payment.php` verifies with `hash_equals` and spends; a
bare GET therefore cannot create an order, and more than five attempts in ten
minutes are refused. A mapping row in the `creating` state then locks the order
while the payment is created, so a second tab or a double click cannot start a
second AneePay payment. AneePay has no idempotency key, so if the API answer is
lost the module looks for the payment it just created — by amount and order
reference — instead of retrying blind.

If saving the mapping fails after the payment already exists, the order is not
cancelled: the failure is logged with the payment ID and checkout URL, a private
order note says it needs attention, and the customer is sent to the checkout.

## Result pages

Success and fail render the same template and are told apart by the real status
of the payment, resolved on the server before the page is printed: the module
calls `GET /payments/{id}`, throttled to one call per order per five seconds.
The page therefore shows the right thing with JavaScript disabled:

- **paid** — the payment is confirmed, the order number and the charged amount
  are shown;
- **failed** — the payment did not go through, with **Try again**; the button is
  only offered here, so a customer who actually paid is never sent back to the
  checkout;
- **pending** — the payment is still on chain, with the address, the amount and
  an **I already paid** button.

While the payment is pending the page polls the status after 5 seconds, then 15,
then every 30 seconds for at most 30 minutes. When that budget is spent the
polling stops and the page offers **Check again**, which resets the timer. Each
request waits for the previous one, so a slow API never stacks calls.

The result and check controllers identify the order through a signed cookie
(`<id_order>.<expiry>.<hmac>`). The expiry lives inside the value because
PrestaShop has no per-key cookie lifetime; it is 24 hours and is renewed on
every view, at most once a minute. The cookie jar's own expiry is left alone —
PrestaShop already makes it persistent for 20 days, and calling
`Cookie::setExpire()` would shorten the whole shopper session to our TTL.

## Order statuses

Each payment status maps to a PrestaShop order state, with these defaults:

| AneePay status | Default order state  | Default behaviour                  |
| -------------- | -------------------- | ---------------------------------- |
| `pending`      | Awaiting payment     | the order is visible, stock reserved |
| `success`      | Payment accepted     | payment recorded, order note written |
| `failed`       | Payment error        | stock released                     |
| `cancelled`    | Payment canceled     | stock released                     |

- The state is written through `OrderHistory`, so the customer sees it in their
  account and the shop can email on it, exactly as for a manual state change.
- The webhook also appends a line to the order's **internal note**, the one the
  admin order page shows. PrestaShop has no note per history entry, only a
  single field on the order, so the module appends instead of overwriting and
  keeps the notes the merchant already wrote.
- `success` is final. A late or duplicated `failed`/`cancelled` never downgrades
  a paid order.
- A repeated delivery of the same status is a no-op: no second history entry, no
  second stock release.
- Unknown statuses are ignored rather than guessed.
- Stock is restored once. The module records that it already did so, and does
  not release stock for an order whose state was already an error state.

## Webhook

AneePay sends `POST` to the **Status** URL above with an
`X-AneePay-Signature` header: the hex HMAC-SHA256 of the raw request body, keyed
with the webhook secret. The module verifies it before reading a single field.

Processing order:

1. **Signature** — compared with `hash_equals`, byte-exact. An empty secret or an
   empty header fails closed with `401`.
2. **Payload** — must be JSON, must carry a status from
   `pending|success|failed|cancelled`, and `timestamp` must be numeric when the
   payload also carries `version` or `event_id`. Any other status answers `400`.
3. **Deduplication** — the delivery is claimed by `event_id`, or by
   `sha256(body)` for legacy payloads. A retry returns `200` with
   `{"success":true,"duplicate":true}` and changes nothing. Rows are pruned
   after 7 days.
4. **Order lookup** — by order ID (with a matching mapping row), then by
   `payment_id`, then by `operation_id` (the 128-bit integer is kept exact and
   also decoded to a UUID), then by an `#N` reference in the description.
   Nothing found answers `404`.
5. **Sandbox gate** — a sandbox payment can never complete a live order. A
   mismatch answers `200` with `{"success":false,"ignored":"sandbox_mismatch"}`
   and logs an error.
6. **Apply** — the status is applied idempotently. If applying throws, the
   answer is `500` and the deduplication claim is released, so AneePay's retry
   works.

`timestamp` is informational: authorisation is the signature alone, and there is
no freshness window. Replay protection is the `event_id` deduplication above.

See [Webhooks](../webhooks/overview.md) and
[Payload and signature](../webhooks/payload-and-signature.md) for the payload
format shared by all integrations.

## Status sync (cron fallback)

AneePay sends a webhook only on `success`. A failed payment is visible only
through `GET /payments/{id}`, so the module polls on its own schedule:

```cron
*/5 * * * * curl -fsS "https://shop.example.com/index.php?fc=module&module=ps_aneepay&controller=cron&secret=<cron_secret>" > /dev/null
```

One run:

- answers `403` when the secret does not match `hash_equals`;
- takes a lock for 300 seconds so two ticks never overlap (a lock older than
  600 seconds is treated as stale and taken over);
- polls the **oldest 100** pending orders no older than **7 days**;
- applies whatever status the API reports, exactly like a webhook;
- closes abandoned payments: an order older than **Abandoned Payment Expiry**
  (default 120 minutes) is moved to the **cancelled** state — or to **failed**
  when no cancelled state is configured — once the API confirms the payment did
  not go through. `0` disables this, and the cron then only reports statuses
  and never cancels an order or releases its stock;
- skips an order when the API answer is a timeout, a `5xx` or a `429`: an
  unknown answer never closes an order;
- prunes the request log once the retention window has passed;
- prints JSON counters: `{"success":true,"checked":N,"updated":N,"expired":N,"failed":N}`
  — `failed` counts orders whose status could not be applied, not failed
  payments.

## Test mode

Test mode forces USDC on Amoy and marks every payment as sandbox. Amounts,
signatures and redirects behave exactly as in live mode, so the whole flow can
be rehearsed for free. Two things need Amoy funds: paying from a wallet, and
seeing an order reach `Payment accepted` through a real webhook.

A sandbox payment never completes a live order, and a live payment never
completes a sandbox one — the webhook gate compares the flags and answers
`200 {"success":false,"ignored":"sandbox_mismatch"}` on a mismatch.

See [Sandbox](../sandbox.md) for test funds.

## Logs

| Where              | Table             | Retention | Contents                                                        |
| ------------------ | ----------------- | --------- | --------------------------------------------------------------- |
| Settings → log     | `ps_aneepay_log`  | 14 days   | Method, endpoint, status, latency, truncated request/response body |
| Webhook dedup      | `ps_aneepay_event`| 7 days    | Claimed `event_id` or body hash, status, applied flag            |

The webhook secret is never written to either table. Error responses are logged
even with the debug log off.

## Data and uninstall

| What                    | Default behaviour                                              |
| ----------------------- | -------------------------------------------------------------- |
| `ps_aneepay_order`      | kept on uninstall, one row per order, unique `id_order`         |
| `ps_aneepay_log`        | kept on uninstall                                               |
| `ps_aneepay_event`      | kept on uninstall                                               |
| Upgrading from 1.1.x    | `upgrade/upgrade-1.2.0.php` adds the `stock_restored` column automatically |

Set **Keep data on uninstall** to **Delete** to drop the tables on uninstall.

## Troubleshooting

| Symptom                                     | Cause and fix                                                                                     |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Orders stay in *Awaiting payment*            | The webhook never arrived or was rejected. Check the request log, the secret and that the Status URL is public. |
| Webhook answered `401`                      | Empty or wrong **Webhook Secret**, or the signature header was stripped by a proxy.               |
| Webhook answered `400`                      | Body was not JSON, carried an unknown status, or `timestamp` was not numeric.                     |
| Webhook answered `404`                      | No order matched. The payment belongs to another shop, or the order was already deleted.          |
| Customer paid, order still pending          | Use **Reconcile payments** for the last day, or **Sync a payment** with the payment ID.            |
| `failed` counter greater than 0 in cron     | The API answered with an error for those orders. The request log has the status code.             |
| Settings will not save                      | Account ID must be a UUID, and each order state must be selected.                                  |
| Redirect lands on a page without an order   | The signed cookie expired or was lost. The page still renders the pending state; reopen the link from the AneePay payment. |

## Related sections

- [Account setup](../getting-started/account-setup.md)
- [Sandbox](../sandbox.md)
- [Webhooks](../webhooks/overview.md)
- [Payload and signature](../webhooks/payload-and-signature.md)
- [Troubleshooting](troubleshooting.md)
- [Beta limitations](limitations-beta.md)
- [Custom integration](custom-integration.md)
- [Plugin development](plugin-development.md)
