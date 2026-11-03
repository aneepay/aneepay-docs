# Developers

This section is for AneePay developers and operators: architecture, local development, contracts, testing, and operations.

## Components

- `django/` — web application, merchant dashboard, partner program, and payment listener.
- `fastapi/` — HTTP API and x402 facilitator.
- `foundry/` — smart contracts and deployment.
- PostgreSQL — shared database.
- `swarm/` — production deployment, backups, and monitoring.

## Topics

- Architecture and data ownership.
- Local development with `docker compose up --watch`.
- Configuration and environment variables.
- Smart contracts and deployment.
- Testing: unit, integration, BDD, and Anvil.
- CI/CD and releases.
- Observability, operations, and backup restoration.
- Security and known limitations.

## Related sections

- [API](../api/overview.md) — HTTP API contracts.
- [x402](../x402/index.md) — protocol and gateway contracts.
- [Reference](../reference/index.md) — contract addresses and networks.
