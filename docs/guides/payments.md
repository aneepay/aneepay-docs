# Payments

Working with payments in Aneepay.

## Creating a payment

```python
payment = client.payments.create(
    amount=1000,
    currency="USD",
    description="Order payment",
    return_url="https://example.com/success",
)
```

## Payment statuses

| Status | Description |
|--------|-------------|
| `pending` | Awaiting payment |
| `succeeded` | Successfully paid |
| `failed` | Payment failed |
| `refunded` | Refunded |
