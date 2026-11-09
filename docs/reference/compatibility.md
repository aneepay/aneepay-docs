# Compatibility

What works with AneePay today: networks and tokens, wallets and browsers, CMS
versions, and the SDK. Addresses and fee rules live in
[Networks, tokens, and fees](../payments/networks-tokens-fees.md) — this page
only states what is supported.

## Networks and tokens

| | Production | Sandbox |
| --- | --- | --- |
| Network | Polygon PoS mainnet, chain ID 137 | Polygon Amoy testnet, chain ID 80002 |
| API value | `network: "polygon"` | `network: "amoy"` (forced by `?sandbox=yes`) |
| Tokens | USDT, USDC, DAI | USDC (test) |
| x402 settlement | `eip155:137`, USDC | Not serviceable |
| Split payments | Yes | No (`split_sandbox_unsupported`) |

Gas is paid by the customer in POL on both networks. Full token addresses and
decimals: [Networks, tokens, and fees](../payments/networks-tokens-fees.md).

## Wallets and browsers

| Surface | Requirement |
| --- | --- |
| Hosted checkout | Any current browser that can run a wallet — the checkout discovers injected wallets via EIP-6963 |
| Tested wallet | MetaMask (browser extension and the mobile in-app browser) |
| Payment calls | EIP-1193 provider; the checkout handles approvals, network switching, and gas estimation |
| Server-side API calls | Any HTTP client — `curl`, `httpx`, `requests`, `fetch` |

!!! tip "Mobile wallets"
    On mobile, the QR code path with the MetaMask app is the tested route —
    see [Hosted checkout and dApp](../payments/checkout-and-dapp.md).

No desktop browser is excluded by design; if a wallet extension injects an
EIP-1193 provider, the checkout works.

## CMS plugin requirements

| Platform | Requirement |
| --- | --- |
| WordPress + WooCommerce | WordPress 6.0+, WooCommerce 6.0+ (tested to 9.4), PHP 7.4+, HPOS compatible, classic checkout (shortcode) |
| OpenCart | OpenCart 3.x, PHP 7.4+ |
| PrestaShop | PrestaShop 1.7.0–8.x, PHP 7.4+ |

Shopware and Bitrix have no published plugin — use the
[custom integration recipe](../cms/custom-integration.md). Platform-specific
details: [CMS overview](../cms/index.md).

## x402 SDK

| Item | Value |
| --- | --- |
| Package | `aneepay-x402` (PyPI) |
| Runtime | Python 3.10+ |
| Dependencies | Self-contained: `httpx` and `pydantic` ship with it |
| Protocol | x402 wire v2, scheme `exact`/EVM only |
| Status | Production/Stable |

Install and first route: [SDK quickstart](../x402/quickstart-sdk.md).

## Related sections

- [Statuses and error codes](statuses-and-codes.md)
- [Networks, tokens, and fees](../payments/networks-tokens-fees.md)
- [Known limitations](../developers/known-limitations.md)
- [Sandbox](../sandbox.md)
