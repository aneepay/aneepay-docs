# Changelog

Product-level changes to AneePay: features, platforms, and capabilities that
became available or changed. **API surface** changes (endpoints, request and
response fields) are listed separately in the
[API changelog](api/changelog.md).

Entries are added when something ships; dates are added as releases are cut.
Earlier history predates this changelog.

## Baseline

| Date | Change | Notes |
| --- | --- | --- |
| — | Payment acceptance on Polygon (chain ID 137) | USDT, USDC, DAI; hosted checkout; 0.5% on-chain fee; non-custodial settlement |
| — | Sandbox on Amoy (chain ID 80002) | `?sandbox=yes`, test USDC, real testnet payments with webhooks |
| — | Webhooks | Signed with `X-AneePay-Signature`, delivered on `success`, 8 retries with exponential backoff |
| — | Split payments | Up to 100 recipients, shares in basis points, production capability |
| — | x402 support | HTTP transport, wire v2, `aneepay-x402` SDK (Production/Stable), per-merchant gateway clones |
| — | CMS plugins | WooCommerce, OpenCart 3.x, PrestaShop 1.7/8 |
| — | Partner program | 10% of the platform fee, lifetime attribution, DAI payouts |
| — | Merchant dashboard | Magic-link login, accounts, payments, CSV export, metrics |
| — | Reconciliation | Payment listing with filters and CSV export |

## What gets listed here

- New payment capabilities and supported networks or tokens.
- New or retired CMS plugins and platform compatibility changes.
- x402 SDK releases that change public behavior (Protocol versions are noted
  in the [x402 section](x402/index.md)).
- Dashboard and partner program changes visible to external users.
- Documented non-features that change status (for example, a capability in
  [Known limitations](developers/known-limitations.md) becoming available).

## What is not listed here

- Endpoint and schema changes → [API changelog](api/changelog.md).
- Documentation-only updates → the repository history.
- Cosmetic dashboard changes that do not affect available actions.

## Related sections

- [API changelog](api/changelog.md) · [Roadmap](reference/roadmap.md)
- [Versioning and deprecation](api/versioning-and-deprecation.md)
