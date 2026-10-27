# Quick Start

A step-by-step guide to connecting with Aneepay.

## 1. Get your API keys

Sign up for an account and create API keys under **Settings → API** in the dashboard.

## 2. Install the SDK

```bash
pip install aneepay
```

## 3. Create your first payment

```python
from aneepay import Aneepay

client = Aneepay(api_key="your_api_key")

payment = client.payments.create(
    amount=1000,
    currency="USD",
    description="Order #1 payment",
)

print(payment.url)
```

## 4. Set up webhooks

Configure webhook URLs in the dashboard to receive payment status notifications.

See the [Webhooks](guides/webhooks.md) guide.
