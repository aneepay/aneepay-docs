# Accounts

An account is the unit of identity for the AneePay API: it owns a domain, a
receiving wallet, three callback URLs, and a webhook secret. Accounts are
managed only here, in the dashboard. The public API has no endpoints to create,
update, or delete accounts.

## The accounts list

**`/accounts/`** (the **Accounts** tab) lists your accounts, ten per page,
with **Previous** / **Next** pagination.

- Each account is an accordion row showing a safety badge and the domain:
  - `Fine` - the domain passed the safety check;
  - `Not Safe` - the domain is flagged, payments are rejected with **403**.
- Expanding a row shows the account card.
- If you have no accounts, the dashboard sends you to
  [`/accounts/create/`](#creating-an-account) automatically.
- Only accounts **you own** are listed. Opening the URL of another user's
  account returns **404**.

### The account card

| Item               | What it shows                                                        |
| ------------------ | -------------------------------------------------------------------- |
| `ID`               | Account UUID - your API key, sent as `X-Account-Id`                   |
| `EVM Wallet`       | Address that receives the net payment amount                         |
| `Success URL`      | Where the customer lands after a successful payment                  |
| `Fail URL`         | Where the customer lands after a failed payment                      |
| `Status URL`       | Your server endpoint that receives the success webhook               |
| `Webhook Secret`   | The secret that keys `X-AneePay-Signature`                           |

Buttons on the card:

| Button                       | Action                                                     |
| ---------------------------- | ---------------------------------------------------------- |
| **Edit**                     | Open the [edit form](#editing-an-account)                  |
| **Scan Transactions**        | Open the wallet on `polygonscan.com` in a new tab          |
| **Account Metrics (Prometheus)** | Open the [per-account metrics](metrics.md) endpoint     |
| **Delete Account**           | Delete the account immediately (POST, no confirmation step)  |

!!! warning "The card is sensitive"

    The card prints the account UUID and the webhook secret **every time you
    open it**. Both are credentials: do not screen-share the card, and never
    paste either value into frontend code, logs, or public repositories. The
    account UUID is the `X-Account-Id` header value and should live only in
    server-side configuration.

## Creating an account

**`/accounts/create/`**

Fill in five fields:

| Field         | On-screen label          | Rules                                                                 |
| ------------- | ------------------------ | --------------------------------------------------------------------- |
| `domain`      | Specify your domain      | Required, unique, normalized (see below); use the ASCII/Punycode form for internationalized domains |
| `wallet`      | Enter your wallet        | Required, valid EVM address, stored checksum-normalized (EIP-55)      |
| `success_url` | Enter the URL            | Required, `http`/`https`, public host only                            |
| `fail_url`    | Enter the URL            | Required, `http`/`https`, public host only                            |
| `status_url`  | Enter the URL            | Required, `http`/`https`, public host only                            |

Two acknowledgment switches above the **Create** button must be turned on
before the button becomes active. **Cancel** returns you to the accounts list.

!!! success "You will see this confirmation"

    `Merchant account created`

### What the server checks

#### Domain

- Normalized before saving: scheme, `www.`, and path are stripped, the value
  is lowercased - `https://www.Example.com/shop` is stored as
  `example.com`. Keep `host:port` if you enter one.
- Must be unique across the platform - otherwise `This domain already exists`.
- Checked against Google Safe Browsing when the account is created; a flagged
  domain is rejected (see [error messages](#error-messages-you-may-see)).

#### Callback URLs (`success_url`, `fail_url`, `status_url`)

- Must use `http` or `https` and contain a host.
- Hosts that are not reachable from the public internet - loopback, private,
  link-local, and reserved addresses - are rejected. The URLs must be reachable
  by AneePay's servers.
- These are pages on **your** site, not AneePay pages - see
  [Account setup](../getting-started/account-setup.md#account-fields).

#### Wallet

- Any valid EVM address; an invalid one is rejected with
  `Invalid EVM address format`.
- Stored checksum-normalized, so `0xab58...` becomes `0xAb58...`.

### Error messages you may see

| Message                             | Cause                                              |
| ----------------------------------- | -------------------------------------------------- |
| `Domain field is required`          | Empty domain                                       |
| `Enter a valid domain URL`          | Domain could not be parsed                         |
| `This domain already exists`        | Another account already uses this domain           |
| `The domain must not be empty.`     | Empty domain at the safety check                   |
| `This domain is marked as unsafe by Google.` | The domain is on Google Safe Browsing        |
| `Domain verification error: network request failed` | The safety check could not reach Google |
| `Success payment URL is required`   | Empty `success_url`                                |
| `Failed payment URL is required`    | Empty `fail_url`                                   |
| `Payment status URL is required`    | Empty `status_url`                                 |
| `URL must use http or https`        | Callback URL has another scheme                    |
| `URL must contain a host`           | Callback URL has no host                           |
| `private or reserved IP addresses are not allowed` | Callback URL points to a non-public address |
| `EVM wallet is required`            | Empty wallet                                       |
| `Enter a valid EVM address` / `Invalid EVM address format` | Not an EVM address   |
| `Failed to create merchant account` | The account could not be saved                     |

## Editing an account

**`/accounts/<account_id>/update/`** - opened with **Edit** on the account
card. The same five fields and the same validation as creation; changes apply
to future payments and webhooks.

!!! success "You will see this confirmation"

    `Account settings updated`

!!! failure "Save rejected"

    `Changes not saved. Please check your input` - fix the field errors shown
    in the form.

Things you **cannot** change here:

| Field                        | Why                                                              |
| ---------------------------- | ---------------------------------------------------------------- |
| Account UUID (`id`)          | It is your API key; changing it means re-integrating             |
| `webhook_secret`             | There is no rotation control in the dashboard or the API         |
| `is_safe`                    | Set only by the safety check, not by you                         |

## Deleting an account

**`/accounts/<account_id>/delete/`**

- **Delete Account** on the account card (and on a `Not Safe` card) removes
  the account **immediately** - the button submits right away; there is no
  confirmation dialog.
- Opening the delete URL directly (**GET**) shows a confirmation page with the
  ID, domain, and wallet: **Confirm Delete** removes the account and returns
  to the accounts list with `Merchant account deleted`, **Cancel** goes back.

!!! warning "Deleting an account deletes its payments"

    Payment history and webhook delivery records are removed together with the
    account. CSV exports are generated on demand and are not stored, so download
    any report you need **before** deleting - see
    [Payments and export](payments-and-export.md).

Account deletion is available in the dashboard; the API has no such endpoint.
An account you do not own returns **404** on both the edit and the delete URL.

## Domain safety (`Not Safe` badge)

`is_safe` tells you the domain is not listed in known malicious-domain
databases. Payments from an account with a `Not Safe` badge are rejected with
**403** (sandbox requests are exempt - see [Sandbox](../sandbox.md)).

- A newly created account can show `Not Safe` until the first automatic domain
  check records a result.
- The domain is re-checked **when you sign in**, for every account that has
  not been checked in the last 7 days. There is no manual "re-check" button.
- An account with the `Not Safe` badge shows remediation instructions instead
  of the usual card:
    1. Verify the flag in the
       [Google Transparency Report](https://transparencyreport.google.com/safe-browsing/search).
    2. If the site was compromised, scan it (VirusTotal, Sucuri SiteCheck,
       Quttera), remove the malicious code, update the CMS and plugins, and
       change passwords.
    3. Submit a review request in
       [Google Search Console](https://search.google.com/search-console)
       under **Security & Manual Actions -> Security Issues -> Request Review**.
- Only **Delete Account** is available on a `Not Safe` card - you cannot edit
  the account until the flag clears.

If you believe the flag is a mistake, fix the site, wait for the next check
(triggered by signing in again), or contact support.

## Related sections

- [Account setup](../getting-started/account-setup.md) - field semantics for
  your integration (`Origin` check, signature verification, key rotation).
- [Payments and export](payments-and-export.md) - what your accounts receive.
- [Metrics](metrics.md) - per-account counters exposed by the dashboard.
- [Security best practices](../security/best-practices.md) - keeping the
  account UUID and webhook secret safe.
