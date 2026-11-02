# Plugin development

This page is for developers building an AneePay payment plugin for their own CMS
or framework. It collects the security rules, packaging conventions, and release
practice used by the official plugins — the reference implementations are the
[WooCommerce](woocommerce.md), [OpenCart](opencart.md), and
[PrestaShop](prestashop.md) plugins.

## Anatomy of a plugin

Every AneePay plugin implements the same seven integration points:

| Piece              | Responsibility                                                                                                                            |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Settings           | Account ID, Webhook Secret, domain, token/network, sandbox, rate source, order-status mapping.                                            |
| Checkout hook      | On order creation: convert the amount, call `POST /payments/` server-side, store `payment_id`/`operation_id`, redirect to `checkout_url`. |
| Order record       | Persist the payment link and conversion context on the order (meta or a mapping table).                                                   |
| Webhook route      | A public endpoint used as `status_url`: verify signature → resolve order → apply status → answer 2xx.                                     |
| Result pages       | `success_url` / `fail_url` on the store, plus a "payment pending" screen with a status check.                                             |
| Status sync        | Background polling of pending orders (platform cron or a scheduled endpoint) as a webhook fallback.                                       |
| Reconciliation     | Use `GET /accounts/{account_id}/payments` in support tooling, not in the payment path.                                                    |

The full behavioral recipe (without platform glue) is
[Custom integration](custom-integration.md).

## Security requirements

These are not optional — a plugin that skips them can lose payments or expose the
account:

- **Server-side calls only.** `POST /payments/` must never run in the customer's
  browser: `X-Account-Id` is an API key.
- **Fail-closed signature verification.** If the secret, the
  `X-AneePay-Signature` header, or the comparison is missing, reject with `401`
  and change nothing. Compare with a constant-time function
  (`hash_equals`, `hmac.compare_digest`, `crypto.timingSafeEqual`) over the
  **raw body bytes** — never over re-serialized JSON.
- **Strict order matching.** Resolve the order by `payment_id` /
  `operation_id` (and only then by `description`), and only for orders actually
  created by your plugin.
- **Idempotent status application.** Applying the same status twice must be a
  no-op; `success` is terminal and must never be downgraded; unknown statuses
  must be ignored.
- **Never log `webhook_secret`** or the account UUID. Request logs must be
  redacted and capped (the official plugins keep the last ~50 entries).
- **Protect your own endpoints.** Status-check AJAX/polling endpoints need an
  ownership check (order key, session, or customer) plus a nonce or rate limit —
  otherwise any visitor can read or advance someone else's order.
- **Sign transient state.** Result pages usually identify the order from a
  cookie or query parameter; sign it with an expiry (HMAC with a server secret)
  so it cannot be forged for an arbitrary order id.
- **Keep TLS verification on.** Never disable certificate or host verification in
  your HTTP client — it exposes the account credentials to interception.
- **Gate fulfillment on `is_sandbox`.** Sandbox payments must not ship goods or
  credit balances ([Sandbox](../sandbox.md)).

## Amounts and identifiers

- Convert with **decimal/integer math**, not binary floats:
  `shop total → USD → token`, then round the token amount **up** to 2 decimals
  (the merchant's favor). Parse API decimals as decimal strings.
  See [Amounts and rounding](../payments/amounts-rounding-and-limits.md).
- `operation_id` is a **128-bit unsigned integer**. Decode JSON with
  big-integers-as-strings (`JSON_BIGINT_AS_STRING` in PHP, `json` with
  `useBigIntegers`/string parsing elsewhere) — a float loses precision and the
  order will never match. In PHP, convert `operation_id` back to the payment UUID
  with an integer-safe routine (the plugins ship one).
- Keep the customer-visible amount identical to what you sent: show the
  conversion breakdown at checkout, exactly like the official plugins do.

## Packaging

| Platform      | Artifact                               | Package layout                                                                                                                   |
| ------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| WooCommerce   | `aneepay.zip`                          | Zip whose root folder is `aneepay/` containing `aneepay.php` (plugin header with `Version:`)                                     |
| OpenCart 3.x  | `aneepay-<version>.ocmod.zip`          | `upload/` (`admin/`, `catalog/`, `system/`) + `install.xml` manifest; no core file modifications                                 |
| PrestaShop    | `ps_aneepay.zip`                       | Root folder `ps_aneepay/`, `config.xml` manifest, `logo.png`, and an `index.php` in **every** directory (PrestaShop requirement) |

Validate before shipping: `php -l` on every file, the platform's structural
checks (manifest present, required headers/files), and a clean install on a fresh
store of the target version.

## Versioning

- Keep **one canonical version** for a release and mirror it everywhere it is
  visible: the WordPress plugin header, `install.xml`, and the PrestaShop
  `config.xml`. Generate any manifest that repeats the version at build time so
  it can never drift from the banner users see.
- Use semantic versioning. A version bump that changes behavior belongs in the
  release notes.
- After an upgrade, migrate stored data in place (add columns, don't require
  manual SQL) — the AneePay plugins upgrade their mapping tables on the first
  settings-page visit.

## Release pipeline

Whatever tooling you use, a release should walk the same steps in the same
order, because each one catches a class of defect the previous one cannot:

1. **Lint** every PHP file (`php -l`) and every template; a syntax error in a
   rarely loaded class only surfaces on the store that happens to reach it.
2. **Validate the package structure** for the target platform:
   - WordPress/WooCommerce — a zip with a single top-level folder named after
     the plugin, the main PHP file carrying the `Plugin Name` / `Version` /
     `Requires PHP` headers, and an `uninstall.php` if you clean up.
   - OpenCart — an OCMOD zip containing `install.xml` and the mirrored file
     tree under `upload/`, with a `<version>` matching the release.
   - PrestaShop — a zip with the module folder containing `config.xml`
     (`<version>`, `<displayName>`, compatibility range) and an `index.php`
     silence file in every directory.
3. **Clean-install on a fresh store** of the oldest and newest supported
   platform version — not an upgrade of your own dev store.
4. **Run the full loop in sandbox**: create a payment, pay on the test network,
   verify the webhook signature, confirm status transitions, and confirm the
   fallback sync catches a deliberately dropped webhook.
5. **Bump the version, tag, and attach the artifact** to the release. Ship the
   built zip as an immutable artifact: never let users build from a moving
   branch, and never overwrite a published file.

A release checklist you can copy:

- [ ] `php -l` clean on every file
- [ ] manifest version == release version
- [ ] structure matches the platform's expected layout
- [ ] clean install on a fresh store, oldest + newest supported version
- [ ] sandbox payment end-to-end, including webhook and sync fallback
- [ ] upgrade path tested on a store with existing orders
- [ ] artifact attached to the tag and checksum recorded

## Compatibility and testing

- Declare platform compatibility honestly in the manifest (WordPress plugin
  header, `ps_versions_compliancy`, OpenCart version range) and test against the
  oldest and newest supported versions.
- Declare framework features you rely on (WooCommerce HPOS compatibility is one
  the official plugin declares).
- Test the full loop in sandbox: create a payment with `?sandbox=yes`, pay on
  Amoy, verify the webhook signature, confirm the order transitions, and confirm
  the sync fallback catches a deliberately dropped webhook. See
  [Testing your integration](../testing-your-integration.md).

## Keep the core separable

Split your code into **platform-agnostic logic** and **CMS glue**:

| Pure logic (shareable)                            | CMS glue (must stay per platform)                      |
| ------------------------------------------------- | ------------------------------------------------------ |
| API client (create/get payment, error mapping)    | Checkout hooks, order model/meta, templates            |
| Fiat → USD → token conversion (rate + rounding)   | Currency sources and rate tables                       |
| HMAC-SHA256 signature verification (fail-closed)  | HTTP request plumbing, raw-body capture                |
| `operation_id` ↔ payment UUID conversion          | Cron/scheduler integration, settings UI                |

Keeping the boundary clean from day one pays off: the pure logic can be
unit-tested without a store, ported to another platform, and reviewed without
CMS knowledge.

## Related sections

- [Custom integration](custom-integration.md) — the behavior to implement.
- [Webhooks](../webhooks/overview.md) — the contract your webhook route fulfills.
- [Security best practices](../security/best-practices.md) — merchant-side rules.
- [Troubleshooting](troubleshooting.md) — what users will report.
