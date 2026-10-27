# x402

x402 is a payment protocol for AI agents and machine clients. A resource server returns `402 Payment Required`, the client signs a payment, and AneePay verifies and settles it on-chain.

## The role of AneePay

AneePay acts as a facilitator: it verifies the signed payment, initiates settlement through a per-merchant gateway, and returns the result. Funds go directly to the merchant; the platform does not hold them.

## Capabilities

- x402 v2 wire format with the `exact` scheme for EVM.
- EIP-3009 `transferWithAuthorization`.
- Per-merchant gateway clones (EIP-1167/CREATE2).
- Python SDK `aneepay-x402` in Production/Stable status.
- Endpoints `/x402/supported`, `/x402/merchant`, `/x402/verify`, and `/x402/settle`.

## Topics

- SDK quickstart.
- Protocol and wire format.
- Facilitator API.
- Gateway contracts.
- Testing and mock facilitator.
- Security and known limitations.

## Related sections

- [API](../api/index.md) — x402 endpoints and authentication.
- [Developers](../developers/index.md) — contracts and architecture.
