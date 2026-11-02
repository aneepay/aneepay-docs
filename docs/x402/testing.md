# Testing

The x402 SDK is designed for **offline tests**: no chain, no facilitator, no
network. Two seams make that possible — `httpx.MockTransport` for the real
facilitator client, and a duck-typed `FakeFacilitator` for the middleware.

!!! note "Run async tests without decorators"

    A convenient setup is `pytest-asyncio` with `asyncio_mode = "auto"`: plain
    `async def test_…` functions then need no `@pytest.mark.asyncio`.

## Mock the facilitator transport

`X402FacilitatorClient` takes any `httpx.AsyncClient`, so an
`httpx.MockTransport` intercepts every facilitator call. This exercises the
**real** client code — URL building, headers, and error mapping:

```python
import httpx
import pytest

from x402_sdk import X402FacilitatorClient


@pytest.fixture
def transport():
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path == "/x402/supported":
            return httpx.Response(200, json={
                "kinds": [{
                    "x402Version": 2,
                    "scheme": "exact",
                    "network": "eip155:80002",
                }],
            })
        raise AssertionError(f"unexpected call: {request.url.path}")

    return httpx.MockTransport(handler)


async def test_supported(payments, transport):
    client = X402FacilitatorClient(
        payments,
        client=httpx.AsyncClient(transport=transport),
    )
    try:
        supported = await client.supported()
        assert [k.network for k in supported.kinds] == ["eip155:80002"]
    finally:
        await client.aclose()   # no-op when `client` is caller-owned
```

!!! warning "Do not reach the network in tests"

    Without a transport, the client would call the real facilitator URL from
    your `PaymentConfig`. Always inject a mock (or a `FakeFacilitator`) in
    unit tests; reserve live calls for explicit staging runs.

## Fake facilitator for middleware tests

The middleware only needs `verify`, `settle`, and `aclose` — so a plain object
with those methods is a valid facilitator (duck typing). A `FakeFacilitator`
also records calls, which is how you assert **ordering**:

```python
from x402_sdk import SettleResponse, VerifyResponse


class FakeFacilitator:
    def __init__(self, is_valid=True, success=True, invalid_reason=None):
        self.is_valid = is_valid
        self.success = success
        self.invalid_reason = invalid_reason
        self.verify_calls = []
        self.settle_calls = []

    async def verify(self, request):
        self.verify_calls.append(request)
        return VerifyResponse(
            isValid=self.is_valid, invalidReason=self.invalid_reason
        )

    async def settle(self, request):
        self.settle_calls.append(request)
        return SettleResponse(
            success=True,
            transaction="0xdead",
            network="eip155:80002",
            amount="10000",
        )

    async def aclose(self):
        ...
```

```python
async def test_paid_route(fake_client):
    fake = FakeFacilitator()
    response = await fake_client(paid_request, fake)

    assert response.status_code == 200
    # verify_calls before settle_calls
    assert fake.verify_calls and fake.settle_calls
```

Because the fake records both calls, a regression that settles without
verifying (or settles a failing handler) fails the test immediately.

## Standard test matrix

The SDK suite pins this behavior — mirroring it in your integration tests
catches wiring mistakes early:

| Scenario                                         | Expected result                                                  |
| ----------                                       | -----------------                                                |
| No `PAYMENT-SIGNATURE` header                    | `402` + `PAYMENT-REQUIRED`, facilitator never called             |
| Valid signature, facilitator accepts, handler OK | `200` + `PAYMENT-RESPONSE`; `/verify` then `/settle` in order    |
| Malformed header (bad base64/JSON)               | `402` with a client-safe message, **no** `/verify` call          |
| Facilitator returns `isValid: false`             | `402` with its code (e.g. `invalid_exact_evm_payload_signature`) |
| `authorization.to` ≠ `payTo` or amount mismatch  | `402` from local checks, **no** `/verify` call                   |
| Handler returns ≥ 400                            | Pass-through status, **no** `/settle`, no `PAYMENT-RESPONSE`     |
| Facilitator settle returns failure               | `402` with `unexpected_settle_error`                             |
| Facilitator transport error / HTTP ≥ 400         | `402` containing `FacilitatorError` text                         |
| `accepts` empty in the offer                     | `ConfigError` at build time                                      |

## Testing your own routes

1. **Build offers once** in a fixture — the same immutable snapshot production
   uses.
2. **Drive the middleware** through the Starlette/FastAPI test client with a
   signed test authorization (or a fake facilitator that accepts everything).
3. **Assert idempotency**: replay the same `PAYMENT-RESPONSE`/transaction to
   your handler and confirm it does not double-deliver — the handler runs
   *before* settlement, so this is on you
   ([Troubleshooting](troubleshooting.md#known-limitations)).
4. **Keep amounts as strings** in fixtures; `build_amount("0.05", 6)`, never
   float arithmetic.

## Related sections

- [SDK quickstart](quickstart-sdk.md) — the code under test.
- [Security](security.md) — what the signature checks actually guarantee.
- [Troubleshooting](troubleshooting.md) — when a test fails in the wrong way.
