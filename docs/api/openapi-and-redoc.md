# OpenAPI and ReDoc

The API contract is published as an OpenAPI 3.1 document at
`https://api.aneepay.com/openapi.json`. ReDoc renders the same document for
humans.

## URLs

| URL | What it is |
| --- | --- |
| <https://api.aneepay.com/redoc> | Human-readable documentation (ReDoc). The API root `/` redirects here. |
| <https://api.aneepay.com/openapi.json> | The machine-readable OpenAPI 3.1 document. |
| <https://api.aneepay.com/docs> | Swagger UI is **disabled** - only ReDoc and the raw document are served. |

```bash title="Terminal"
# Read the documentation in a browser:
#   https://api.aneepay.com/redoc

# Download the schema
curl -o openapi.json https://api.aneepay.com/openapi.json
```

The document declares `info.title = "AneePay API"`, `info.version = "1.0.0"`,
the `Payment` and `x402` tags, and the `AccountId` security scheme
(`X-Account-Id` header) on the four operations that require it.

## Generating a client

Any OpenAPI 3.1 generator works. Example with the OpenAPI Generator CLI:

```bash title="Terminal"
# Python (httpx)
npx @openapitools/openapi-generator-cli generate \
  -i https://api.aneepay.com/openapi.json \
  -g python \
  -o ./aneepay-client
```

```bash title="Terminal"
# TypeScript (fetch)
npx @openapitools/openapi-generator-cli generate \
  -i https://api.aneepay.com/openapi.json \
  -g typescript-fetch \
  -o ./aneepay-client
```

!!! warning "Generation is a starting point, not an integration"

    Generated clients do not encode the rules that matter: keep `X-Account-Id`
    server-side, branch on `code` in problem responses, verify webhook
    signatures, and handle the x402 `200`-with-`isValid:false` pattern. See
    [Authentication](authentication.md), [Errors](errors.md), and
    [Webhooks](webhooks.md).

## Known schema quirks

- Error examples in the document use `request_id: "-"` as a placeholder; real
  responses carry a UUID.
- The schema has no `servers` block - construct every URL from the base
  `https://api.aneepay.com` yourself.

## Related sections

- [Overview](overview.md) - base URL, content types, conventions.
- [Endpoints](endpoints.md) - endpoint map with links to scenario pages.
- [Versioning and deprecation](versioning-and-deprecation.md) - how the contract evolves.
- [Changelog](changelog.md) - published changes.
