# Account metrics

Each account exposes its payment counters as a **Prometheus** endpoint. The
dashboard links to it from two places:

- the **Account Metrics (Prometheus)** button on the [account card](accounts.md#the-account-card);
- the **Account** column of the [payments list](payments-and-export.md#columns).

```text
GET /accounts/<account_id>/metrics/
```

The response is plain text in the Prometheus exposition format
(`text/plain; version=0.0.4; charset=utf-8`) with the label set
`account_id="<uuid>", account_domain="<domain>"`.

!!! warning "Anyone with the URL can read it"

    The endpoint is addressed by the account UUID and is **not** protected by
    your session. Treat the metrics URL like the account UUID itself: do not
    publish it, and scrape it only from infrastructure you control.

## Available metrics

| Metric                                    | Type    | Meaning                                              |
| ----------------------------------------- | ------- | ---------------------------------------------------- |
| `payments_in_progress`                    | Gauge   | Payments currently in `pending` state (live count)   |
| `payments_successful_total`               | Gauge   | Lifetime number of successful payments               |
| `payments_failed_total`                   | Gauge   | Lifetime number of failed payments                   |
| `payments_processing_duration_seconds_count` | Gauge | Number of confirmed payments measured                |
| `payments_processing_duration_seconds_sum` | Gauge   | Total confirmation time of those payments, seconds   |
| `payments_processing_duration_seconds_bucket{le="..."}` | Gauge | Cumulative count per duration bucket |

All series are exported as gauges: the `*_total`, `_count`, `_sum`, and
`_bucket` values are cumulative figures that Prometheus scrapes repeatedly.

### Duration buckets

`payments_processing_duration_seconds_bucket` is exported with cumulative
upper bounds `le` of:

```text
0.1, 0.5, 1.0, 2.5, 5.0, 10.0, 30.0, 60.0, inf
```

(`inf` is the open-ended last bucket, equivalent to `+Inf` in native
Prometheus histograms.)

The measured duration of a payment is the time between its creation and its
confirmation (`confirmed_at - created_at`), recorded when the payment is
confirmed. Failed payments are counted in `payments_failed_total` but do not
contribute to the duration histogram.

### How the numbers are maintained

- `payments_in_progress` is computed at scrape time from the current
  `pending` payments, so it follows the real state of the account.
- The counters and histogram data are updated when a payment reaches its final
  state, which is why they are lifetime figures for the account - they are not
  reset by filters or by exports.

## Scraping

Point Prometheus at the endpoint of every account you operate:

```yaml
scrape_configs:
  - job_name: aneepay-account
    metrics_path: /accounts/<account_id>/metrics/
    static_configs:
      - targets: ["aneepay.com"]
```

Useful starting queries:

```promql
# Successful payments across your accounts
sum(payments_successful_total)

# Payments waiting right now
sum(payments_in_progress)

# Share of payments confirmed within 10 seconds
sum(payments_processing_duration_seconds_bucket{le="10.0"})
  /
sum(payments_processing_duration_seconds_count)
```

!!! note "Not the same as the payment list"

    Metrics are cumulative counters for monitoring and alerting. For
    period-accurate reporting - "how many payments succeeded this month" -
    use the [payments list](payments-and-export.md) or the
    [account payments API](../payments/reconciliation.md), which can be
    filtered by date and status.

## Related sections

- [Accounts](accounts.md) - where the metrics button lives.
- [Payments and export](payments-and-export.md) - the list behind the
  counters.
- [Reconciliation](../payments/reconciliation.md) - the API equivalent for
  reporting.
