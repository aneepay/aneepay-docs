# API — Overview

An overview of the Aneepay REST API.

## Base URL

```
https://api.aneepay.com/v1
```

## Response format

All responses are returned as JSON:

```json
{
  "id": "pay_123",
  "status": "succeeded",
  "amount": 1000,
  "currency": "USD"
}
```

## Error codes

| Code | Description |
|------|-------------|
| `400` | Bad request |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not found |
| `429` | Rate limit exceeded |
