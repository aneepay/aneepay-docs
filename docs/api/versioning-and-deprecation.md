# Versioning and deprecation

The AneePay API has **no version segment in the URL** - there is no `/v1` and
no place to put one. Everything documented here is the single current version,
described by `info.version` in the [OpenAPI document](openapi-and-redoc.md)
(currently `1.0.0`).

## What that means for you

- You always call the same paths on `https://api.aneepay.com`.
- Contract changes arrive in place and are recorded in the
  [Changelog](changelog.md).
- There is no parallel old/new version to migrate between - changes are
  evolutionary and announced before they break anything.

## Compatibility rules

### Non-breaking (no announcement required)

- New endpoints are added.
- New **optional** request parameters are added.
- New fields appear in responses - **clients must ignore unknown response
  fields** instead of failing parsing.
- New error `code` values may appear - always keep a fallback branch for codes
  you do not recognize.

### Breaking (announced in the changelog first)

- Removing or renaming an endpoint, field, or error code.
- Changing a field's type, format, or meaning (including amount formats or
  status values).
- Making an existing optional request parameter required, or adding a new
  required one.
- Changing authentication or signature rules.

!!! note "Requests are strict, responses are permissive"

    Request bodies reject unknown fields with `422 validation_error`, so
    sending a field before the server supports it is an error. Response
    payloads are the opposite: new fields may appear at any time, so parsing
    must be tolerant.

## Deprecation policy

- No endpoint or field listed in this documentation is currently deprecated.
- AneePay does not send `Deprecation` or `Sunset` response headers today. If a
  deprecation is introduced, it is announced in the [Changelog](changelog.md)
  first, remains functional for a migration period, and is only then removed -
  the changelog will state both dates.
- A request to an unknown path answers `404` with `code: "http_error"` in the
  usual problem+json envelope - that is how a removed endpoint behaves.

## What is versioned separately

| Surface | Versioning |
| --- | --- |
| HTTP API paths | Unversioned; `info.version` in `openapi.json`. |
| x402 wire protocol | Pinned to `x402Version: 2`; other versions are rejected with `400 invalid_x402_version` ([x402 protocol](../x402/protocol-and-wire.md)). |
| Webhook payload | Carries its own `version` field (currently `1`) - see [Payload and signature](../webhooks/payload-and-signature.md). |

## Related sections

- [Changelog](changelog.md) - published changes.
- [OpenAPI and ReDoc](openapi-and-redoc.md) - download and diff the contract.
- [Errors](errors.md) - `http_error` and the shared envelope.
