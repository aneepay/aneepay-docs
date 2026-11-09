# Payments and export

The **Payments** tab (`/dashboard/payments/`) shows every payment of every
account you own, newest first, with filters and a CSV export. It requires an
active session - anonymous visitors are sent back to the login form.

## Filters

All four filters are optional and are sent as GET parameters:

| Parameter     | Meaning                                | Values                                     |
| ------------- | -------------------------------------- | ------------------------------------------ |
| `status`      | Payment status                         | `pending`, `success`, `failed`, `cancelled`, or all |
| `account`     | Restrict to one of your accounts       | Account UUID, or all accounts              |
| `created_from`| Period start, inclusive                | Date (`YYYY-MM-DD`), from 00:00 UTC        |
| `created_to`  | Period end, inclusive                  | Date (`YYYY-MM-DD`), up to 23:59:59 UTC    |

- Press **Apply** to run the filter, **Reset** to clear it, **Export CSV** to
  download the same selection.
- Pagination links keep the active filters, so page 2 of a filtered list stays
  filtered.
- `created_from` later than `created_to` is rejected: the filters are ignored,
  the unfiltered list is shown, and a warning explains the validation error.
- The list is scoped to your own accounts only; payments of other merchants
  never appear.

`cancelled` is a terminal state set by AneePay; customers cannot cancel a
payment.

An empty result shows **"No payments yet."**

## Columns

| Column         | Content                                                                 |
| -------------- | ----------------------------------------------------------------------- |
| Date           | Creation time, `D Mon YYYY HH:MM` (for example, `3 Nov 2026 11:34`)     |
| Status         | Badge: `Success` (green), `Failed` (red), `Cancelled` (grey), `Pending` (yellow) |
| Type           | `Standard Payment`, `Splits Payment`, or `Confirmed Payment`            |
| Amount         | Payment amount, up to 6 decimals                                        |
| Token / Network| Token and network, e.g. `USDC / polygon`                                |
| Account        | Domain of the account - links to its [metrics](metrics.md) endpoint     |
| Details        | Expands the detail row (below)                                          |

There is **no separate payment detail page**: everything extra is inside the
**Details** disclosure under the row.

### Detail fields

| Field          | Meaning                                                       |
| -------------- | ------------------------------------------------------------- |
| `Description`  | The payment description (public - see [Security and privacy](../payments/security-and-privacy.md)) |
| `Fee`          | Platform fee taken from the payment                           |
| `Net Amount`   | What the recipients received                                  |
| `Recipients`   | Split recipients, when the payment was a split                |
| `Is Sandbox`   | `Yes` for Amoy test payments - keep them out of real ledgers  |
| `Confirmed`    | Whether the payment is confirmed                              |
| `Confirmed At` | Confirmation time                                             |
| `x402`         | Present on x402 payments: the x402-specific fields of the payment |

For a payment's public API representation (`operation_id`, `tx_hash`, nested
`payment_details`), use [`GET /payments/{id}`](../payments/status-and-polling.md) -
the dashboard is a monitoring view, not the contract.

## CSV export

**Export CSV** on the Payments tab downloads
`GET /dashboard/payments/export/` with the current filters attached.

- The **whole filtered set** is exported in one file - pagination does not
  apply.
- The file streams as `text/csv; charset=utf-8` with a UTF-8 BOM, so it opens
  correctly in Excel; the filename is `payments_YYYY-MM-DD.csv` (export day).
- Non-numeric values that could be interpreted as formulas by spreadsheets
  (those beginning with `=`, `+`, `-`, `@`, or a leading tab, carriage return,
  or newline) are prefixed with `'`, so an export cannot execute anything in
  your spreadsheet. Negative numbers such as `-12.5` are left unchanged.

### CSV columns

`Date`, `Status`, `Type`, `Amount`, `Token`, `Network`, `Account`,
`Description`, `Fee`, `Net Amount`, `Confirmed`, `Confirmed At`, `Recipients`,
`Is Sandbox`

`Account` is the account domain; the other detail columns come from the
payment's stored details, with lists and objects serialized as compact JSON.
`Date` is an ISO 8601 timestamp.

### Limits and errors

| Case                                   | Result                                                        |
| -------------------------------------- | ------------------------------------------------------------- |
| More than 60 exports in 60 seconds     | **429** (rate limit, counted per client IP)                   |
| More than **10 000** rows match        | **413** `Too many payments to export; narrow the filters.` - no file is generated |
| Invalid filters                        | **400** with the validation message                           |
| Not signed in                          | Redirect to the login form                                    |

Narrow the period or pick a single account when an export is refused for size.

!!! tip "Exports are for accounting, not for integration"

    For programmatic reconciliation use
    [`GET /accounts/{account_id}/payments`](../payments/reconciliation.md) -
    it is paginated, filterable by the same criteria plus `type` and amount
    bounds, and has no export limits.

## Not available in this list

| Not available                | Instead                                                        |
| ---------------------------- | -------------------------------------------------------------- |
| Text search                  | Filter by account and period                                   |
| Amount range / payment type filters | The API list: [`GET /accounts/{id}/payments`](../payments/reconciliation.md) |
| Refunds or cancellation      | Not supported at all - see [Non-features](../payments/refunds-cancellations-and-non-features.md) |
| Creating payments            | [`POST /payments/`](../payments/create-payment.md)             |

## Related sections

- [Reconciliation](../payments/reconciliation.md) - the API counterpart and
  the reconciliation workflow built on it.
- [Status and polling](../payments/status-and-polling.md) - reading a single
  payment.
- [Sandbox](../sandbox.md) - interpreting the `Is Sandbox` column.
- [Metrics](metrics.md) - what the Account column links to.
