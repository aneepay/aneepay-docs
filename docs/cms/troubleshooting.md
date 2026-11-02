# CMS plugin troubleshooting

Symptom → cause → fix for the three official plugins. Platform-agnostic problems
(API errors, webhooks, reconciliation) are covered in the general
[Troubleshooting](../troubleshooting.md) page; this page only lists what is
specific to the plugins.

## Installation and settings

| Symptom                                            | Likely cause                                                                                                    | Fix                                                                                                                          |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Payment method not listed after install            | WooCommerce inactive (WC plugin), payment extension not installed (OpenCart), module not installed (PrestaShop) | Activate WooCommerce; run **Extensions → Payments → AneePay → Install**; install the module via **Upload a module**          |
| Settings will not save                             | Account ID is not a UUID, or Webhook Secret is empty                                                            | Enter the account UUID exactly; the secret must be non-empty at least once (a blank field on re-save keeps the stored value) |
| "AneePay Account ID is not configured" at checkout | Account ID field empty                                                                                          | Fill it in on the gateway settings page                                                                                      |
| `403 account_not_found`                            | Wrong account UUID in the plugin                                                                                | Copy the UUID from the AneePay dashboard                                                                                     |
| `403 domain_mismatch`                              | `Origin` host differs from the account `domain` (often `www` vs bare domain, or http vs https host mismatch)    | Make the Domain setting and the account domain identical                                                                     |
| `403 account_not_safe`                             | Domain still flagged by the reputation check                                                                    | Wait for the review, contact support, or enable Test mode (sandbox bypasses the check)                                       |
| Test connection fails but the API works from curl  | Missing/incorrect Domain setting, or the account UUID belongs to another environment                            | Fix the Domain setting; confirm the UUID ([Account setup](../getting-started/account-setup.md))                              |

## Checkout

| Symptom                                                          | Likely cause                                                   | Fix                                                                                                                                              |
| ---------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| AneePay missing from checkout (WooCommerce)                      | Block-based Cart/Checkout page                                 | Use the classic checkout shortcode — blocks integration is not implemented                                                                       |
| Customer sent back to checkout with an error                     | API rejected the payment (validation, `is_safe`, connectivity) | Read the message; check Account ID, sandbox state, and the request log on the settings page                                                      |
| Two payments for one order                                       | — (should not happen)                                          | The plugins reuse a pending payment for the same order; if you see duplicates, note both payment IDs and contact support with `operation_id`s    |
| Token amount differs from the order total                        | Shop currency is not USD; rate source; deliberate round-up     | Expected: shop total → USD → token, rounded **up** to 2 decimals; check the conversion breakdown on the payment card and the rate source setting |
| Sandbox payment charged in USDC although USDT is configured      | Sandbox forces USDC                                            | Expected behavior; disable Test mode for live payments ([Sandbox](../sandbox.md))                                                                |
| Customer's redirect lands on the result page with no order shown | Signed cookie expired or another browser/session               | Harmless: the page re-syncs status; the order itself is confirmed server-side                                                                    |

## Order statuses

| Symptom                                                        | Likely cause                                                                                                         | Fix                                                                                                                                       |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Order stays `pending` although the payment succeeded           | Webhook never arrived (`status_url` not set in the account panel, wrong URL, or store unreachable from the internet) | Set `status_url` from the plugin settings page; meanwhile the sync/cron fallback confirms the order ([Webhooks](../webhooks/overview.md)) |
| OpenCart: `failed` / `cancelled` never change the order status | Status mapping defaults to "no status" (only pending/paid have defaults)                                             | Map all four statuses on the extension settings page                                                                                      |
| Order was downgraded after being paid                          | — (should not happen)                                                                                                | `success` is terminal in all plugins; a downgrade indicates a manual status change — restore it and report with the payment ID            |
| Stock not released after a failed payment                      | Order never entered a stock-reserving status, or restoration already ran                                             | A one-time marker on the order prevents a double restock; release manually if the order was created outside the plugin flow               |
| Order note/history missing the operation ID                    | Payload had no `operation_id`                                                                                        | Use the payment ID stored on the order / in the mapping table for support                                                                 |

## Webhooks

| Symptom                                     | Likely cause                                                                                    | Fix                                                                                          |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Webhook receiver answers `401`              | Webhook Secret in the plugin differs from the account's secret (or is empty)                    | Copy the secret from the AneePay panel into the plugin; the plugins verify **fail-closed**   |
| Webhook rejected with `400 stale_timestamp` | Store server clock skewed by more than 24 hours                                                 | Fix NTP/time sync on the store server                                                        |
| Webhook returns `404`                       | No order matches the payload (payment created by another integration, or mapping table missing) | Check the stored mapping (order metadata) and the payment ID                                 |
| Webhooks arrive but nothing changes         | Status not in the whitelist, or status already applied                                          | Only `pending`/`success`/`failed`/`cancelled` are accepted; duplicates are ignored by design |
| No webhook at all for a test payment        | Sandbox still useful — but `status_url` must still be set                                       | Set `status_url`; sandbox webhooks are delivered with `is_sandbox: true`                     |

## Status sync

| Symptom                                                      | Likely cause                                               | Fix                                                                                                 |
| ------------------------------------------------------------ | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| WooCommerce orders confirm only when someone visits the shop | WP-Cron runs on traffic                                    | Schedule a server-side cron against `wp-cron.php`, or shorten the Status Sync Interval              |
| OpenCart/PrestaShop cron returns `403`                       | Missing or wrong `secret` query parameter                  | Use the exact cron URL from the settings page (the secret is generated once and shown there)        |
| Cron URL never runs                                          | Not added to the server crontab                            | Add it: `*/5 * * * * curl -s '<cron-url>' >/dev/null` at the configured interval                    |
| "I already paid" button says forbidden                       | Order opened in another browser/session, or cookie expired | Retry from the session that started the payment; the check endpoint only accepts the owning session |
| Status check seems stuck                                     | Endpoint rate-limits repeat checks (a few seconds)         | Expected; wait a moment or let the cron/webhook catch up                                            |

## Logs and diagnostics

| Platform     | Where to look                                                                                                                   |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| WooCommerce  | **WooCommerce → Status → Logs** (source `aneepay`) after enabling Debug Log; **Request log** panel on the gateway settings page |
| OpenCart     | **Request log** panel on the extension settings page (entries are also persisted)                                               |
| PrestaShop   | **Request log** panel on the module configuration page (entries are also persisted)                                             |

The request log records time, method, endpoint, response code, latency, and a
truncated body — it never contains the Webhook Secret or `X-Account-Id`. Enable
debug logging only while diagnosing, and redact logs before sharing them.

## Before contacting support

<https://t.me/aneepay>

Include:

- platform and version (WooCommerce / OpenCart / PrestaShop + PHP version);
- plugin version (settings page or package name);
- the payment `operation_id` or payment ID;
- a timestamp with timezone, and whether Test mode was on;
- the relevant request-log lines (secrets redacted).

## Related sections

- [General troubleshooting](../troubleshooting.md) — API, webhook, and account errors.
- [Testing your integration](../testing-your-integration.md) — verification checklist.
- [Webhooks overview](../webhooks/overview.md) — delivery contract.
