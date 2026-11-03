# Changelog

Public changes to the AneePay HTTP API: new endpoints and fields, behavioral
changes, deprecations, and removals.

## Baseline

| Date | Change | Notes |
| --- | --- | --- |
| - | **Baseline: `info.version` `1.0.0`** | The surface documented in this section: 4 payment endpoints, 4 x402 endpoints, RFC 7807 errors, no version segment in URLs. |

Nothing has been published since the baseline. Dated entries are added here
whenever the documented surface changes.

## What gets listed

| Category | Meaning |
| --- | --- |
| Added | New endpoints, new request parameters, new response fields. |
| Changed | Behavioral changes to existing endpoints: validation, defaults, limits, error codes. |
| Deprecated | Endpoints or fields that remain functional but should no longer be used. |
| Removed | Endpoints or fields that no longer work. |
| Security | Changes to authentication, authorization, or signature rules. |

## How to detect changes yourself

1. Read this page - every published change lands here first.
2. Diff the OpenAPI document against your stored copy:

```bash title="Terminal"
curl -o openapi-new.json https://api.aneepay.com/openapi.json
diff openapi.json openapi-new.json
```

The OpenAPI document is the published contract. Comparing your saved copy with
the current `/openapi.json` therefore shows the contract changes that matter.
See [OpenAPI and ReDoc](openapi-and-redoc.md).

## What is not tracked here

- On-chain network/token availability changes (see
  [Networks, tokens, and fees](../payments/networks-tokens-fees.md)).
- Dashboard UI changes (see [Dashboard](../dashboard/overview.md)).
- Webhook payload additions documented in
  [Payload and signature](../webhooks/payload-and-signature.md).

## Related sections

- [Versioning and deprecation](versioning-and-deprecation.md) - the policy behind this changelog.
- [OpenAPI and ReDoc](openapi-and-redoc.md) - the machine-readable contract.
- [Errors](errors.md) - error codes that may appear.
