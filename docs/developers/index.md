# Developers

Reference for developers building on AneePay: the published smart contracts,
their security properties, and the boundaries of the current platform.

## In this section

- [Smart contracts](contracts/index.md) — overview, roles, and published addresses.
- [Standard payment contract](contracts/standard-payment.md) — functions, events, errors, and the on-chain fee.
- [Split payment contract](contracts/split-payment.md) — shares, limits, rounding, replay protection.
- [x402 gateway and Factory](contracts/x402-gateway.md) — per-merchant clones and the settlement interface.
- [Security for developers](security.md) — non-custodial model, verified source, enforced properties.
- [Known limitations](known-limitations.md) — what is not implemented today.

## Start here

| Goal | Page |
| --- | --- |
| Integrate payments over HTTP | [API overview](../api/overview.md) |
| Verify an on-chain settlement | [Smart contracts](contracts/index.md) |
| Protect a route with x402 | [SDK quickstart](../x402/quickstart-sdk.md) |
| Design around what does not exist | [Known limitations](known-limitations.md) |

## Related sections

- [API](../api/overview.md) — HTTP API contracts.
- [x402](../x402/index.md) — protocol and gateway contracts.
- [Reference](../reference/index.md) — statuses, compatibility, and roadmap.
- [Security model](../security/security-model.md) — system-level trust boundaries.
