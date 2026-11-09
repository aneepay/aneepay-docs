# AneePay

AneePay is a **strictly non-custodial** crypto payment gateway on **Polygon (PoS)**.
It accepts ERC-20 stablecoins — **USDT, USDC, DAI** — and sends funds directly from
the payer to your wallet. The platform never holds or controls your assets.

| Property | Detail |
| --- | --- |
| Non-custodial | Payer → smart contract → merchant wallet. No custody. |
| Fee | Flat **0.5%**, deducted on-chain by the contract. |
| KYC | None for payments or integration. Onboarding is an automated domain reputation check. |
| Hosted checkout | Ready-made payment page (QR + MetaMask) hosted by AneePay. |
| Webhooks | Signed server-to-server notifications on successful payments. |
| Sandbox | Amoy testnet payments for development without real funds. |

**Base URL:** `https://api.aneepay.com` (unversioned) — full reference at
[`/redoc`](https://api.aneepay.com/redoc).

## Who is this for

=== "Merchant / online store"
    Accept crypto payments on your site: onboarding, first payment, webhooks,
    reconciliation. Start with the [Getting started](getting-started/overview.md)
    section, or install a ready-made [CMS plugin](cms/index.md).

=== "Custom integration"
    You write your own backend: [Quickstart](getting-started/quickstart.md),
    then the [API](api/overview.md) and [webhooks](webhooks/overview.md).

=== "AI agent / machine payments"
    Pay-per-request over HTTP with the x402 protocol: see
    [x402](x402/index.md).

=== "Partner"
    Earn 10% of the platform fee from referred merchants: see
    [Partner program](partner/index.md).

## Sections

- [Getting started](getting-started/overview.md) — product model, quickstart,
  account setup, payment lifecycle, glossary.
- [Merchant](merchant/index.md) — entry point to the merchant documentation.
- [Payments](payments/create-payment.md) — create a payment, checkout, status,
  split payments, reconciliation, fees, refunds, security, idempotency.
- [Webhooks](webhooks/overview.md) — payload, signature verification, delivery,
  retries, and testing.
- [Errors, sandbox, and support](errors/index.md) — error format, sandbox,
  troubleshooting, FAQ, and security best practices.
- [CMS](cms/index.md) — plugins for WooCommerce, OpenCart, PrestaShop.
- [x402](x402/index.md) — protocol, SDK, facilitator API.
- [Partner](partner/index.md) — referral program and payouts.
- [Dashboard](dashboard/overview.md) — accounts, payments, export, and metrics.
- [API](api/overview.md) — endpoints, authentication, errors.
- [Developers](developers/index.md) — platform and contract developer entry point.
- [Smart contracts](developers/contracts/index.md) — standard, split, and x402
  gateway contracts.
- [Reference](reference/index.md) — statuses, networks, tokens, error codes.

## Useful links

- [Website](https://aneepay.com) · [Terms](https://aneepay.com/tos/) ·
  [Privacy](https://aneepay.com/privacy/)
- [API docs (ReDoc)](https://api.aneepay.com/redoc) ·
  [OpenAPI JSON](https://api.aneepay.com/openapi.json)
- [Smart contracts on Polygonscan](https://polygonscan.com/address/0x7AB120ac5060997B5c9AB2F3e891273dd686b8A2#code)
- [GitHub](https://github.com/aneepay) · [Support (Telegram)](https://t.me/aneepay)
