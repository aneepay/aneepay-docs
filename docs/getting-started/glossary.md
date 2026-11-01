# Glossary

Terms used across the AneePay documentation.

| Term | Definition |
| --- | --- |
| **Account** | A merchant unit inside AneePay: domain, receiving wallet, callback URLs, webhook secret. Identified by a UUID (`account_id`). |
| **`X-Account-Id`** | HTTP header carrying the account UUID — the API key for creating payments and listing account payments. Server-side only. |
| **`Origin` check** | Optional secondary request check: if the `Origin` header is present, it must match the account's domain, otherwise **403**. |
| **`is_safe`** | Flag saying the registered domain is not listed in malicious-domain databases (Google Safe Browsing). Payments are rejected with **403** while `false`; sandbox bypasses it. |
| **Magic link** | Passwordless login: a one-time link sent by email, valid 10 minutes. |
| **Hosted checkout** | AneePay-hosted payment page (`checkout_url`) with QR code and MetaMask deep link; handles network switching, balance checks, and the contract call. |
| **`checkout_url`** | The hosted checkout URL returned by `POST /payments/`; redirect the customer there. Format: `https://aneepay.com/payment/{uuid}/`. |
| **`success_url` / `fail_url`** | Pages on the **merchant's** site where the customer's browser is redirected after a successful / failed payment attempt. |
| **`status_url`** | Server endpoint on the **merchant's** site that receives the success webhook. |
| **`webhook_secret`** | Per-account secret used to compute and verify the `X-AneePay-Signature` HMAC. |
| **`X-AneePay-Signature`** | Webhook signature: HMAC-SHA256 hex digest of the raw request body keyed with `webhook_secret`. |
| **`operation_id`** | The payment UUID encoded as a `uint128` integer (`int(payment_id)`). Stored on-chain in `PaymentProcessed`, used in webhooks and for matching orders. Bijective with `payment_id`. |
| **`payment_id`** | The payment's UUID primary key. Recoverable from `operation_id` via `uuid.UUID(int=operation_id)`. Publicly readable (see [public payment read](../api/authentication.md)). |
| **`PaymentProcessed`** | Smart-contract event emitted when funds are moved; the trigger for status confirmation. |
| **Confirmations / finality** | Number of blocks (`PAYMENT_CONFIRMATIONS`, default 12) the listener waits after the event before marking a payment `success`. |
| **0.5% fee** | Flat platform fee (50 basis points), calculated and deducted on-chain inside the contract; the only platform fee. Gas is paid by the payer. |
| **Split payment** | Payment distributed to multiple recipient wallets by shares in basis points (sum = 10000, max 100 recipients; the account wallet must be one of them). `POST /payments/split/`. |
| **Basis points (bps)** | Units of 0.01%: 50 bps = 0.5%, 10000 bps = 100%. Used for fees and split shares. |
| **Sandbox** | Test mode: `?sandbox=yes` forces Amoy (chain ID 80002), test USDC, `is_sandbox: true`, and bypasses `is_safe`. Works in production. |
| **Polygon / Amoy** | Production network (chain ID 137) and test network (chain ID 80002) used by AneePay. |
| **USDT / USDC / DAI** | ERC-20 stablecoins accepted on Polygon; sandbox uses test USDC on Amoy. |
| **Outbox** | Durable storage of outbound webhook deliveries, ensuring retries survive restarts. |
| **Idempotency (webhooks)** | Safe duplicate handling: process each webhook once, keyed by `event_id`, regardless of retries or replays. |
| **Reconciliation** | Matching your order records against AneePay's payment history via `GET /accounts/{account_id}/payments` and/or webhooks. |
| **ReDoc / `openapi.json`** | Auto-generated API reference at `https://api.aneepay.com/redoc` and its machine-readable schema. |
| **Gateway clone** | Per-merchant minimal proxy of the x402 gateway contract (EIP-1167/CREATE2); its `payTo` address receives x402 settlements. |
| **Facilitator** | Server that verifies and settles x402 payments on behalf of a resource server (`/x402/verify`, `/x402/settle`). |
| **x402** | Payment protocol for machines/AI agents: HTTP `402` challenge with signed EIP-3009 authorizations. |
| **Non-custodial** | Funds move payer → contract → merchant wallet; AneePay never holds user assets. |
