# AneePay Documentation - Publication Plan

- **Status:** Publication plan with agreed decisions applied.
- **Goal:** Define the complete set of public documents required for merchants, partners, and solution developers to integrate AneePay without assistance.

## 1. Principles

1. **Public audience only.** Every page is written for merchants, their customers, partners, or developers building solutions on AneePay.
2. **Describe public behavior.** Document the public API, public contracts, supported networks, and observable product behavior only.
3. **One document equals one scenario or one contract.** Do not mix merchant, partner, and developer audiences on the same page.
4. **Do not duplicate legal documents.** Terms of service and privacy remain on the main site; documentation links to them.
5. **The API is unversioned.** Examples use the base URL `https://api.aneepay.com` without `/v1`.
6. **Documentation is English-only.** All published pages, navigation labels, and examples are written in English.
7. **API reference follows the public contract.** The generated OpenAPI reference is the source of truth; guides link to it instead of duplicating schemas.

## 2. Full document list

Legend: **P0** - required for a working documentation set; **P1** - required for completeness; **P2** - optional depth.

### 2.1. Merchant onboarding

| ID | File | Content | Priority |
|---|---|---|---|
| M01 | `index.md` | What AneePay is, non-custodial model, 0.5% fee, Polygon, USDT/USDC/DAI, who it is for, audience routing | P0 |
| M02 | `getting-started/overview.md` | Product and model: funds go directly to the merchant, role of the on-chain payment contract, hosted checkout, what the product does not do | P0 |
| M03 | `getting-started/quickstart.md` | First payment in 10 minutes: registration, account, `POST /payments/`, `checkout_url`, status | P0 |
| M04 | `getting-started/account-setup.md` | Domain, EVM wallet, `success_url`/`fail_url`/`status_url`, `webhook_secret`, `is_safe`, domain verification | P0 |
| M05 | `getting-started/payment-lifecycle.md` | `pending` to `success`/`failed`, `operation_id`, confirmations, finality, no customer cancellation | P0 |
| M06 | `getting-started/glossary.md` | Glossary: operation_id, checkout_url, status_url, gateway clone, facilitator, split, sandbox | P1 |

### 2.2. Payment acceptance

| ID | File | Content | Priority |
|---|---|---|---|
| M07 | `payments/create-payment.md` | `POST /payments/`: headers, body, response, errors, curl/Python/JS/PHP examples | P0 |
| M08 | `payments/checkout-and-dapp.md` | Hosted checkout, QR, wallet deep link, network switching, balance/allowance, redirect to success/fail | P0 |
| M09 | `payments/status-and-polling.md` | `GET /payments/{id}`, public read, status polling, response fields | P0 |
| M10 | `payments/split-payments.md` | `POST /payments/split/`, recipients and shares in bps, limit 100, total 10000, owner among recipients | P0 |
| M11 | `payments/reconciliation.md` | `GET /accounts/{account_id}/payments`, filters, pagination, CSV export, reconciliation with webhooks | P1 |
| M12 | `payments/networks-tokens-fees.md` | Polygon 137 and Amoy 80002, USDT/USDC/DAI addresses, decimals, 0.5% fee, gas, who pays | P0 |
| M13 | `payments/amounts-rounding-and-limits.md` | Amount precision, minimum amount, fee rounding, decimal strings, `description` limits | P1 |
| M14 | `payments/refunds-cancellations-and-non-features.md` | Explicitly: no refunds, no customer cancellation, no subscriptions or recurring payments | P0 |
| M15 | `payments/security-and-privacy.md` | Why `description` is public, what must not be put there, public `GET /payments/{id}`, `X-Account-Id` server-side only | P0 |
| M16 | `payments/idempotency-and-retries.md` | Payment creation idempotency, repeated requests, timeouts, handling unknown responses | P1 |

### 2.3. Webhooks and reconciliation

| ID | File | Content | Priority |
|---|---|---|---|
| M17 | `webhooks/overview.md` | When a webhook is sent, only on `success`, delivery timing and ordering | P0 |
| M18 | `webhooks/payload-and-signature.md` | Payload v1, `event_id`, `operation_id`, `tx_hash`, `fee`, `net_amount`, `X-AneePay-Signature` HMAC-SHA256, verification examples | P0 |
| M19 | `webhooks/delivery-retries-idempotency.md` | Retries: 8 attempts, exponential backoff, idempotency by `event_id`, 2xx requirements | P0 |
| M20 | `webhooks/testing-and-replay.md` | Public test endpoint, sandbox drills, common signature and body errors | P1 |

### 2.4. Errors, sandbox, and support

| ID | File | Content | Priority |
|---|---|---|---|
| M21 | `errors/index.md` | RFC 7807 `application/problem+json`, `code`, `request_id`, HTTP status and error code table | P0 |
| M22 | `sandbox.md` | `?sandbox=yes`, Amoy 80002, USDC, `is_safe` bypass; sandbox is documented as a working capability | P0 |
| M23 | `testing-your-integration.md` | Integration checklist, test scenarios, how to verify webhooks and reconciliation | P1 |
| M24 | `faq.md` | Around 50 merchant, customer, partner, and x402 questions grouped by topic | P0 |
| M25 | `troubleshooting.md` | Symptom, cause, and solution: 403 `is_safe`, 403 Origin, webhook 401, payment pending, wrong network | P0 |
| M26 | `security/best-practices.md` | Merchant checklist: server-side calls, signature verification, idempotency, secrets, `description` | P0 |

### 2.5. CMS integrations

| ID | File | Content | Priority |
|---|---|---|---|
| M27 | `cms/index.md` | Supported platforms: WooCommerce, OpenCart, PrestaShop; common plugin flow, what is configurable | P0 |
| M28 | `cms/woocommerce.md` | Installation, settings, checkout, order statuses, webhook, test mode, troubleshooting | P0 |
| M29 | `cms/opencart.md` | Installation, settings, checkout, order statuses, webhook, test mode, troubleshooting for OpenCart 3.x | P0 |
| M30 | `cms/prestashop.md` | Installation, settings, checkout, order statuses, webhook, test mode, troubleshooting for PrestaShop 1.7/8 | P0 |
| M31 | `cms/custom-integration.md` | General recipe for a custom site: settings, payment creation, redirect, webhook, result pages, reconciliation | P0 |
| M32 | `cms/plugin-development.md` | Building your own plugin: security, packaging, versioning, release | P1 |
| M33 | `cms/troubleshooting.md` | Plugin-specific troubleshooting | P1 |

### 2.6. x402 for AI agents

| ID | File | Content | Priority |
|---|---|---|---|
| M34 | `x402/index.md` | What x402 is, why merchants need it, actors (client, resource server, facilitator, gateway), when to use it; SDK is Production/Stable | P0 |
| M35 | `x402/protocol-and-wire.md` | Wire v2, `exact`/EVM, EIP-3009, `PAYMENT-REQUIRED`/`SIGNATURE`/`RESPONSE` headers, sequence | P1 |
| M36 | `x402/quickstart-sdk.md` | Installing `aneepay-x402`, `PaymentConfig`, protecting routes, testing | P0 |
| M37 | `x402/facilitator-api.md` | `/x402/supported`, `/merchant`, `/verify`, `/settle`, `X-Account-Id`, error codes | P0 |
| M38 | `x402/gateway-contracts.md` | Per-merchant gateway clone, Factory, non-custodial model | P1 |
| M39 | `x402/testing.md` | Testing middleware and using a mock facilitator | P1 |
| M40 | `x402/security.md` | Replay protection, signatures, non-custodial model, threat model; SDK is Production/Stable | P1 |
| M41 | `x402/troubleshooting.md` | Verify/settle errors, `settlement_pending`, wrong network or amount, known limitations | P1 |

### 2.7. Partner program

| ID | File | Content | Priority |
|---|---|---|---|
| M42 | `partner/index.md` | How it works: 10% of the platform fee, lifetime attribution, 30-day cookie, statuses | P0 |
| M43 | `partner/getting-started.md` | Email registration, magic link, DAI wallet setup, referral link | P0 |
| M44 | `partner/commissions-and-payouts.md` | Accrual, 7-day hold, available balance, DAI payouts, payout history, errors | P0 |
| M45 | `partner/faq.md` | Partner questions grouped by topic | P1 |

### 2.8. Merchant dashboard

| ID | File | Content | Priority |
|---|---|---|---|
| M46 | `dashboard/overview.md` | Magic-link login, dashboard overview, available features | P0 |
| M47 | `dashboard/accounts.md` | Create, update, and delete an account; domain, wallet, callbacks, webhook secret | P0 |
| M48 | `dashboard/payments-and-export.md` | Payment list, filters, details, CSV export | P1 |
| M49 | `dashboard/metrics.md` | Account metrics available in the dashboard and their meaning | P2 |

### 2.9. API reference

| ID | File | Content | Priority |
|---|---|---|---|
| M50 | `api/overview.md` | Base URL `https://api.aneepay.com` without version, content type, change policy | P0 |
| M51 | `api/authentication.md` | `X-Account-Id`, `Origin`, `is_safe`, public payment read, no browser calls | P0 |
| M52 | `api/endpoints.md` | Endpoint map: payments, split, accounts, x402, service; links to scenarios and ReDoc | P0 |
| M53 | `api/errors.md` | RFC 7807, codes, examples, `request_id` | P0 |
| M54 | `api/webhooks.md` | Webhook contract and link to the webhooks section | P1 |
| M55 | `api/openapi-and-redoc.md` | How to open `/redoc` and `/openapi.json`, how to generate a client | P0 |
| M56 | `api/changelog.md` | Public API changelog: additions, changes, deprecations | P1 |
| M57 | `api/versioning-and-deprecation.md` | Change and deprecation policy without a version in the URL | P2 |

### 2.10. Developer reference

| ID | File | Content | Priority |
|---|---|---|---|
| D01 | `developers/contracts/index.md` | Contract overview and roles, published contract addresses | P1 |
| D02 | `developers/contracts/standard-payment.md` | Standard payment contract: functions, events, errors, fee | P1 |
| D03 | `developers/contracts/split-payment.md` | Split payment contract: shares, limits, events | P1 |
| D04 | `developers/contracts/x402-gateway.md` | x402 gateway and Factory contracts | P1 |
| D05 | `developers/security.md` | Non-custodial model, verified contracts, security properties | P1 |
| D06 | `developers/known-limitations.md` | Not implemented: refunds, subscriptions, in-store payments, MCP | P1 |

### 2.11. Reference, meta, and legal

| ID | File | Content | Priority |
|---|---|---|---|
| R01 | `reference/statuses-and-codes.md` | Unified table of public statuses and error codes | P1 |
| R02 | `reference/compatibility.md` | Supported networks, tokens, browsers, wallets, and CMS versions | P2 |
| R03 | `reference/roadmap.md` | Public roadmap without commitments | P2 |
| R04 | `security/vulnerability-disclosure.md` | How to report a vulnerability, scope, response targets | P1 |
| R05 | `security/security-model.md` | Non-custodial model, on-chain fee, verified contracts | P1 |
| R06 | `legal/terms-and-privacy.md` | Links only to `aneepay.com/tos/` and `/privacy/`, no copying | P1 |
| R07 | `llms.txt` | Machine-readable documentation map for AI agents | P1 |
| R08 | `changelog.md` | Public product changelog | P1 |

## 3. Publication constraints

| Constraint | Reason |
|---|---|
| Public audience only | Content is written for external users and solution developers |
| No actions unavailable to external users | Only capabilities available to external users are documented |
| No non-public environments or configuration | They are not available to external users |
| No duplicated API schemas | The public OpenAPI reference is the source of truth |
| No copied legal text | Terms of service and privacy are hosted on the main site |

## 4. Accepted product decisions

1. **CMS platforms.** Only WooCommerce, OpenCart, and PrestaShop are supported. Shopware and Bitrix are not claimed as supported; only the general `cms/custom-integration.md` recipe applies to them.
2. **Sandbox is enabled.** It is documented as a working capability: `?sandbox=yes`, Amoy 80002, USDC, and `is_safe` bypass.
3. **`POST /payments/{payment_id}/confirm` is not documented.** The public API has no such endpoint.
4. **Webhook retries.** A webhook is delivered up to 8 times with exponential backoff.
5. **Split payments are in production.** They are documented as a working feature.
6. **No subscriptions or recurring payments.** Refunds and customer cancellation are also unsupported.
7. **The API is unversioned.** The base URL is `https://api.aneepay.com`, without `/v1`.
8. **Amount precision.** Amounts are accepted as decimal strings; standard checkout rounds to 2 decimals, while machine payments may use up to 6 decimals.
9. **`GET /payments/{id}` is public.** `X-Account-Id` is required for payment creation and account payment listing.
10. **The x402 SDK is Production/Stable.** Its public status and known limitations are documented in the x402 section.

## 5. Definition of sufficient documentation

The documentation is considered sufficient when:

1. A new merchant can complete the path without assistance: registration, account, first payment, webhook, reconciliation.
2. A WooCommerce, OpenCart, or PrestaShop owner installs the plugin according to the instructions and accepts a payment.
3. An x402 developer protects a route using the quickstart and understands how to verify and settle a payment.
4. A partner registers, receives a referral link, and understands how commissions are accrued and paid out.
5. A solution developer can integrate using the public API and contract reference without assistance.
6. No document contradicts the public API or public contract behavior, and all old placeholder pages are removed.
7. All P0 documents are published and pass `mkdocs build --strict` plus link checking.
