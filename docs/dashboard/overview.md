# Dashboard overview

The AneePay dashboard is the merchant control panel on the main site. It is
where you sign in without a password, create and maintain the accounts your
integration uses, watch payments arrive, and export them for accounting.

The dashboard is not a separate host - it lives on `https://aneepay.com`
under a handful of paths, and every page carries the same header: the login
form when you are signed out, the **Logout** button when you are signed in.

!!! note "Merchant dashboard, not partner dashboard"

    This section describes the **merchant** dashboard. The partner program has
    a separate interface of its own - see
    [Partner program](../partner/index.md).

## Signing in

AneePay uses **passwordless login** based on a magic link:

1. Enter your email address in the header form on any page and press **Go**.
   The hint under the field reads: *Magic link valid for 10 minutes.
   Passwordless registration.*
2. Open the message titled **"Your AneePay login link"** and follow the link.

!!! success "You will see this confirmation"

    `Login link sent. Check your email (Valid for 10 min).`

| Property  | Value                                                                       |
| --------- | --------------------------------------------------------------------------- |
| Validity  | 10 minutes from the moment it was sent                                      |
| Reuse     | Single use - opening the same link twice fails                              |
| Landing   | Always the accounts list at `/accounts/`, even if you requested it elsewhere |
| Session   | Lasts up to 2 weeks and ends with **Logout** in the header                  |

- Signing in for the first time with an email address creates the profile for
  it automatically - there is no separate registration step.
- An expired, already-used, or malformed link opens the **Invalid Token** page
  ("We apologize, but the token used for this link has expired or is
  invalid."). Go back and request a fresh link.
- If you are already signed in, opening the site takes you straight to
  `/accounts/`.
- If you have no merchant accounts yet, you land on the account creation form
  at `/accounts/create/` automatically.

## Pages

| Page                     | URL                                      |
| ------------------------ | ---------------------------------------- |
| Accounts list            | `/accounts/`                             |
| Create an account        | `/accounts/create/`                      |
| Edit an account          | `/accounts/<account_id>/update/`         |
| Delete an account        | `/accounts/<account_id>/delete/`         |
| Payments list            | `/dashboard/payments/`                   |
| CSV export               | `/dashboard/payments/export/`            |
| Account metrics          | `/accounts/<account_id>/metrics/`        |

The dashboard itself is a two-tab shell - **Accounts** and **Payments** - plus
a third tab, **Create Payment Link**, that is shown disabled because the
feature is not available yet.

## What the dashboard gives you

| Capability                                            | Where                                          |
| ----------------------------------------------------- | ---------------------------------------------- |
| Create, edit, and delete merchant accounts            | Accounts tab                                   |
| Read your account UUID (`X-Account-Id`) and webhook secret | Account card                               |
| Domain safety status (`Fine` / `Not Safe`) and how to fix a flag | Account card                    |
| Open the wallet on Polygonscan                        | **Scan Transactions** on the account card      |
| Payments of all your accounts with filters            | Payments tab                                   |
| Export the filtered payment list to CSV               | **Export CSV** on the Payments tab             |
| Per-account Prometheus metrics                        | **Account Metrics (Prometheus)** / the Account column |

## What the dashboard does not do

| Not available                     | Instead                                                            |
| --------------------------------- | ------------------------------------------------------------------ |
| Creating payments                 | The API: [`POST /payments/`](../payments/create-payment.md)        |
| Refunds, cancellations, subscriptions | [Non-features](../payments/refunds-cancellations-and-non-features.md) |
| Payment links ("Create Payment Link" tab) | Not implemented - the tab is disabled                     |
| Rotating the webhook secret or the account UUID | [Account setup](../getting-started/account-setup.md#key-rotation) |
| Passwords, profiles, team members | One profile per email address; login is the magic link only        |
| Withdrawals and payouts           | The [partner dashboard](../partner/index.md) only                  |

## In this section

| Page                                            | Covers                                                       |
| ----------------------------------------------- | ------------------------------------------------------------ |
| [Accounts](accounts.md)                         | Create, edit, delete; fields, validation, domain safety      |
| [Payments and export](payments-and-export.md)   | Payment list, filters, details, CSV export                   |
| [Metrics](metrics.md)                           | Per-account Prometheus metrics and their meaning             |

## Related sections

- [Account setup](../getting-started/account-setup.md) - what every account
  field means for your integration.
- [Reconciliation](../payments/reconciliation.md) - the API counterpart of the
  payments list and CSV export.
- [Troubleshooting](../troubleshooting.md) - symptom-to-fix table, including
  dashboard errors.
- [Security best practices](../security/best-practices.md) - handling the
  account UUID and webhook secret.
