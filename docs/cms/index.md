# CMS

AneePay plugins for popular CMS platforms. The plugins accept USDT, USDC, and DAI through hosted checkout and update order status via webhooks.

## Supported platforms

- **WooCommerce** — WordPress plugin.
- **OpenCart 3.x** — payment module.
- **PrestaShop 1.7/8** — payment module.

## How it works

1. The merchant installs the plugin and provides `account_id`, `webhook_secret`, and the site domain.
2. The customer selects AneePay at checkout.
3. The plugin creates a payment through the API and redirects the customer to `checkout_url`.
4. After a successful payment, AneePay sends a webhook.
5. The plugin verifies the signature and marks the order as paid.

## Custom sites

For sites without a ready-made plugin, use the general integration recipe: create a payment on the server, redirect to checkout, handle webhooks, and reconcile through the payments list.

## Related sections

- [Merchant](../merchant/index.md) — accepting payments and webhooks.
- [API](../api/index.md) — creating payments and authentication.
