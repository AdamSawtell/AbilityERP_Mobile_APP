# SAW019 — Invoice Capture (same-box OCR)

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#19](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/19) |
| **Slug** | `SAW019_invoice_capture` |
| **Dev host** | `3.107.53.69` |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Invoice Capture inbox in iDempiere: attach PDF → **Process Selected Invoice** anytime (or optional nightly batch). Shared OCR + Draft AP Vendor Invoice creation on the same EC2 (poppler `pdftotext` + Tesseract). No separate OCR worker.

## Source of truth

- Plugin: `idempiere-plugins/com.aberp.invoicecapture/`
- Shared service: `com.aberp.invoicecapture.service.InvoiceCaptureService`
- Processes: `ProcessSelectedInvoice`, `ProcessInvoiceCaptureBatch`
- AD SQL: `sql/00` … `sql/08`

## Dependencies (app)

None.
