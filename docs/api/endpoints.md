# Endpoints

Reference of API endpoints.

## Payments

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/payments` | Create a payment |
| `GET` | `/payments/{id}` | Retrieve a payment |
| `GET` | `/payments` | List payments |
| `POST` | `/payments/{id}/refund` | Refund a payment |

## Webhooks

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/webhooks` | Create a webhook |
| `GET` | `/webhooks` | List webhooks |
| `DELETE` | `/webhooks/{id}` | Delete a webhook |
