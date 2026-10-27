# Authentication

Authenticating with the Aneepay API.

## Bearer token

Pass your secret key in the header:

```
Authorization: Bearer sk_live_xxxxx
```

## Example

```bash
curl https://api.aneepay.com/v1/payments \
  -H "Authorization: Bearer sk_live_xxxxx"
```

## Key rotation

It is recommended to rotate keys every 90 days.
