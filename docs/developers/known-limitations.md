# Known limitations

What AneePay does not do today. Knowing this before you design an integration
saves time. Everything here describes the current public surface — nothing on
this page is a commitment that any of it will change.

## Not implemented

| Capability | Status | Where to look instead |
| --- | --- | --- |
| Refunds | Not implemented — settlement is final | [Refunds and non-features](../payments/refunds-cancellations-and-non-features.md) |
| Customer cancellation | Not implemented — a pending payment only confirms or fails | [Payment lifecycle](../getting-started/payment-lifecycle.md) |
| Subscriptions and recurring payments | Not implemented — no stored authorizations | [Refunds and non-features](../payments/refunds-cancellations-and-non-features.md) |
| In-store (point-of-sale) payments | Not implemented — acceptance is online only | [Product overview](../getting-started/overview.md) |
| MCP transport for x402 | Not implemented — HTTP transport only in this release | [x402 known limitations](../x402/troubleshooting.md#known-limitations) |
| Fiat rails (cards, bank transfers) | Not implemented — stablecoins on Polygon only | [Networks, tokens, and fees](../payments/networks-tokens-fees.md) |

## Feature-scope limits

| Area | Limit |
| --- | --- |
| Split payments in the sandbox | Not available (`split_sandbox_unsupported`) — production capability |
| Shopware and Bitrix plugins | Not published — use the [custom integration recipe](../cms/custom-integration.md) |
| WooCommerce block-based checkout | Classic checkout (shortcode) only — see [CMS troubleshooting](../cms/troubleshooting.md) |
| x402 networks and tokens | Production `eip155:137` with USDC only; one accepted offer per route |
| x402 wire version | v2 only — v1 requests are rejected with `invalid_x402_version` |
| Supported CMS platforms | WooCommerce, OpenCart, PrestaShop only — see [CMS overview](../cms/index.md) |
| API versioning | No version segment in URLs; changes are tracked in the [API changelog](../api/changelog.md) |
| Refund or reversal path in the x402 SDK | None — handlers must be idempotent because settlement starts as soon as a handler returns a success status |

## Before you build

- [Refunds and non-features](../payments/refunds-cancellations-and-non-features.md)
- [x402 known limitations](../x402/troubleshooting.md#known-limitations)
- [Product changelog](../changelog.md)

## Related sections

- [Contracts](contracts/index.md) · [Security for developers](security.md)
- [FAQ](../faq.md) · [Troubleshooting](../troubleshooting.md)
