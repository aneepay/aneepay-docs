# Security for developers

What the payment system enforces on-chain, what you can verify yourself, and
what remains your responsibility. For your own integration checklist, see
[Security best practices](../security/best-practices.md).

## Non-custodial by construction

- Funds move **payer → fee recipient + recipient** inside one transaction. No
  payment amount is ever held in a balance on our side, so there is no hosted
  pool for payment funds to be frozen, drained, or mismanaged.
- The platform fee is calculated **inside the contract** (0.5%, integer math)
  at settlement time — not by an off-chain invoice you have to trust.
- If any transfer fails, the transaction reverts: the payer keeps the tokens
  and no partial settlement exists.

The system-level view of this model lives in the
[Security model](../security/security-model.md).

## Verified source

The source of every deployed contract is verified on the block explorer, so
the published bytecode matches the published source. Check it yourself:

- Standard payment on mainnet:
  [Polygonscan code tab](https://polygonscan.com/address/0x7AB120ac5060997B5c9AB2F3e891273dd686b8A2#code)
- All addresses and networks: [Contracts overview](contracts/index.md)

!!! warning "Verified source is not an audit"
    Explorer verification proves that the deployed bytecode matches the
    published source. It does not certify the logic. Read the source and the
    properties below before you build on it.

## What the contracts enforce

| Property | Where |
| --- | --- |
| Reentrancy guard around settlement | `nonReentrant` on every settlement function |
| Emergency stop | `pause` / `unpause` stops settlement without touching settled funds |
| Atomic fee and net transfer | One transaction — revert means no settlement |
| Replay protection for splits | The operation key is stored on first processing; identical payloads revert |
| Clone creation cannot be front-run | The factory deploys and initializes a clone in one transaction |
| Settlement authorization (x402) | Only the facilitator address may settle; EIP-3009 signatures are single-use by the token's own rules |
| No native-token surprises | Sending POL to a payment contract reverts (`NativeTokenNotAccepted`) |
| Established primitives | `Ownable`, `ReentrancyGuard`, `Pausable`, `SafeERC20`, `Initializable` |

## What you enforce

- Keep `webhook_secret` and `X-Account-Id` on your server only, and verify
  `X-AneePay-Signature` on every webhook — see
  [Security best practices](../security/best-practices.md).
- Create payments from your backend, never from the browser.
- Treat `description` as public data — see
  [Security and privacy](../payments/security-and-privacy.md).
- Make webhook and status handling idempotent: deliveries are retried and may
  arrive more than once — see
  [Delivery, retries, idempotency](../webhooks/delivery-retries-idempotency.md).

## Reporting a problem

If you find a vulnerability in the API, the hosted checkout, the published
contracts, or the plugins, follow
[Vulnerability disclosure](../security/vulnerability-disclosure.md).

## Related sections

- [Security model](../security/security-model.md)
- [Contracts](contracts/index.md) · [Known limitations](known-limitations.md)
- [x402 security](../x402/security.md)
