# Roadmap

What is available now, what is being considered, and what does not exist.
**Nothing on this page is a commitment**: no dates, no guarantees that a
considered item ships, and no promise that anything stays unchanged. Shipped
changes are recorded in the [changelog](../changelog.md).

## Available now

| Area | Status |
| --- | --- |
| Payment acceptance (USDT/USDC/DAI on Polygon) | Generally available — [Product overview](../getting-started/overview.md) |
| Split payments, up to 100 recipients | Generally available — [Split payments](../payments/split-payments.md) |
| Sandbox on Amoy with `?sandbox=yes` | Generally available — [Sandbox](../sandbox.md) |
| x402 for machine payments (HTTP transport) | Production/Stable — [x402 overview](../x402/index.md) |
| CMS plugins: WooCommerce, OpenCart, PrestaShop | Generally available — [CMS overview](../cms/index.md) |
| Partner program with lifetime attribution | Generally available — [Partner overview](../partner/index.md) |
| Hosted checkout, webhooks, CSV export | Generally available |

## Under consideration

| Item | Note |
| --- | --- |
| Shorter partner referral links | Planned improvement; the current `?ref=` UUID links keep working |

## Not available today

These are documented as non-features, not as pending work — see
[Known limitations](../developers/known-limitations.md):

- refunds and customer cancellation;
- subscriptions and recurring payments;
- in-store payments;
- MCP transport for x402 (HTTP transport only);
- plugins for Shopware and Bitrix.

## How this page changes

When an item moves between sections, it gets a dated entry in the
[changelog](../changelog.md). API surface changes are listed separately in the
[API changelog](../api/changelog.md).

## Related sections

- [Changelog](../changelog.md) · [FAQ](../faq.md)
- [Known limitations](../developers/known-limitations.md)
