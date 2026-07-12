# SAW001 — Paid filter on Notification SR Invoice Send Info

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#1](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/1) |
| **Slug** | `SAW001_paid_filter_invoice_send_info` |

## Goal

Add a **Paid** Yes/No/blank search filter (and display column) to Info Window **Notification SR Invoice Send Info**, using `C_Invoice.IsPaid`.

## Source of truth

- `idempiere-plugins/com.aberp.notification.invoiceinfo/`
- Preflight: `sql/00-preflight-uuids.sql` (in that package)

## Dependencies (app)

None — Info Window / WebUI only.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW001_paid_filter_invoice_send_info-*`
- Prod: thin `AbilityERP-ProdUpdate-SAW001_*` when issuing to a client
