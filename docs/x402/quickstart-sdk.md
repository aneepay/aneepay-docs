# SDK quickstart

`aneepay-x402` is the merchant-side Python SDK: it builds payment offers,
implements the payment middleware, and talks to the AneePay facilitator. The
SDK is **Production/Stable**.

!!! warning "Install the right package"

    `aneepay-x402` is **not** the upstream `x402` PyPI package. It targets the
    AneePay facilitator (`/x402/*` endpoints, `X-Account-Id` account scoping).

## Install

```bash
pip install aneepay-x402
# or
uv add aneepay-x402
```

Requires Python 3.10+. The SDK is self-contained: `httpx`, `pydantic`, and
`starlette` are the only dependencies.

## Configure

```python
from uuid import UUID

from x402_sdk import PaymentConfig, TokenConfig

payments = PaymentConfig(
    facilitator_url="https://api.aneepay.com",
    account_id=UUID("11111111-1111-1111-1111-111111111111"),
    network="eip155:137",
    pay_to="0x1111111111111111111111111111111111111111",
    token=TokenConfig(
        address="0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
        decimals=6,
        name="USD Coin",
        version="2",
    ),
    resource_url="https://api.example.com/report",
    description="Quarterly report",
)
```

| Field                                            | Notes                                                                                                     |
| -------                                          | -------                                                                                                   |
| `facilitator_url`                                | Base URL of the AneePay facilitator; a trailing `/` is normalized away                                    |
| `account_id`                                     | Your AneePay account UUID — sent as `X-Account-Id` **on settle only**, never exposed to clients           |
| `network`                                        | CAIP-2, EVM only: `eip155:<chainId>`                                                                      |
| `pay_to`                                         | The **gateway clone** address from `GET /x402/merchant` — **not** your own wallet (`^0x[a-fA-F0-9]{40}$`) |
| `token`                                          | ERC-20 to accept; `name`/`version` are signed EIP-712 security parameters, not labels                     |
| `resource_url` / `description`                   | What the offer is for; shown in the `402` document                                                        |
| `mime_type`                                      | Defaults to `application/json`                                                                            |
| `max_timeout_seconds`                            | Offer validity hint, default `60`                                                                         |
| `request_timeout_seconds`                        | Per facilitator call, default `10.0`                                                                      |
| `supported_path` / `verify_path` / `settle_path` | Defaults `/x402/supported`, `/x402/verify`, `/x402/settle`                                                |

`PaymentConfig` is an immutable snapshot with `extra="forbid"`: unknown fields
raise `ConfigError` at build time, and later changes to your settings do not
affect an already-built offer.

??? tip "Where do I get `pay_to`?"

    Call `GET /x402/merchant` with `X-Account-Id`. It returns your
    deterministic clone address per network **before** the contract is
    deployed — deployment happens lazily on the first successful settlement.
    See [Facilitator API](facilitator-api.md).

## Build the offer once

```python
from x402_sdk import build_payment_required, build_resource_info

resource = build_resource_info(
    payments,
    resource_url=payments.resource_url,
    description=payments.description,
    mime_type=payments.mime_type,
)

report_offer = build_payment_required(
    payments,
    price="0.05",            # 0.05 USDC — str, int or Decimal
    resource=resource,
    max_timeout_seconds=30,
)
```

!!! warning "Never pass a float expression to `build_amount`"

    `build_amount(0.1 + 0.2, 6)` raises `AmountError` — the binary float
    result cannot be represented exactly. Use `str`, `int`, or `Decimal`:
    `build_amount("0.05", 6) == "50000"`. Build each offer **once at
    startup**, not per request.

Each route gets its own offer (see [Per-route pricing](#per-route-pricing));
the middleware compares the signed amount against it byte-for-byte.

## Protect routes

`require_payment(config, payment_required, *, client=None)` returns a
Starlette-style dispatch function. **Route filtering is your job** — the
middleware protects whatever you apply it to, and only `accepts[0]` of the
offer is enforced.

### Starlette

```python
from starlette.middleware.base import BaseHTTPMiddleware
from x402_sdk import require_payment

async def dispatch(request, call_next):
    if request.url.path == "/health":
        return await call_next(request)          # free route
    offer = REPORT if request.url.path == "/report" else None
    if offer is None:
        return await call_next(request)
    return await require_payment(payments, offer)(request, call_next)

app.add_middleware(BaseHTTPMiddleware, dispatch=dispatch)
```

### FastAPI

```python
from fastapi import FastAPI
from x402_sdk import require_payment

app = FastAPI()
OFFERS = {"/report": report_offer}

@app.middleware("http")
async def payment_gate(request, call_next):
    offer = OFFERS.get(request.url.path)
    if offer is None:
        return await call_next(request)          # free route
    return await require_payment(payments, offer)(request, call_next)
```

Per request the middleware, in order: missing `PAYMENT-SIGNATURE` → `402`;
decode → local checks (scheme, network, asset, `payTo`, exact amount,
`authorization.to`/`value`) → `POST /x402/verify` → handler →
`POST /x402/settle` → `200` + `PAYMENT-RESPONSE`. A handler status ≥ 400
passes through **without settling**.

!!! note "Share one HTTP client in production"

    Without an explicit `httpx.AsyncClient`, the SDK creates a client per
    request — a fresh TLS handshake each time. Pass a shared client to
    `require_payment`/`X402FacilitatorClient` and close it on shutdown.

    ```python
    import httpx
    from x402_sdk import require_payment

    http = httpx.AsyncClient(timeout=10.0)     # created at startup

    async def payment_gate(request, call_next):
        offer = OFFERS.get(request.url.path)
        if offer is None:
            return await call_next(request)
        return await require_payment(payments, offer, client=http)(request, call_next)

    # on shutdown
    await http.aclose()
    ```

## Verify the gate

Start your service, then request a paid route **without** a payment header:

```bash
curl -i https://<your-server>/report
```

You should get `402 Payment Required`, a JSON body describing the offer, and a
`PAYMENT-REQUIRED` header whose base64 payload decodes to the same document.
If you get `200` instead, the route is not matched by your dispatch — the
middleware only protects paths you hand it explicitly.

A `500` at this point usually means a config problem, not a payment problem:
`PaymentConfig` errors surface at build time, and an unreachable
`facilitator_url` only matters once a signed request arrives.

## Per-route pricing

One offer per route keeps pricing explicit and the comparison exact:

```python
REPORT = build_payment_required(
    payments, price="0.05", resource=build_resource_info(
        payments,
        resource_url="https://api.example.com/report",
        description="Quarterly report",
    ),
    max_timeout_seconds=30,
)
EXPORT = build_payment_required(
    payments, price="0.25", resource=build_resource_info(
        payments,
        resource_url="https://api.example.com/export",
        description="Full export",
    ),
)
OFFERS = {"/report": REPORT, "/export": EXPORT}
```

## Test it

The SDK tests are fully offline — no chain, no network:

```python
import httpx
from x402_sdk import X402FacilitatorClient

def handler(request: httpx.Request) -> httpx.Response:
    assert request.url.path == "/x402/supported"
    return httpx.Response(200, json={
        "kinds": [{"x402Version": 2, "scheme": "exact",
                   "network": "eip155:80002"}],
    })

transport = httpx.MockTransport(handler)
client = X402FacilitatorClient(payments, client=httpx.AsyncClient(transport=transport))
```

For middleware ordering, a `FakeFacilitator` duck-typed like the real client
(recording `verify`/`settle` calls) is enough. The full patterns and the
standard test matrix are in [Testing](testing.md).

## Related sections

- [Protocol and wire](protocol-and-wire.md) — what the middleware puts on the
  wire.
- [Facilitator API](facilitator-api.md) — the endpoints the SDK calls.
- [Troubleshooting](troubleshooting.md) — config errors, amounts, limitations.
