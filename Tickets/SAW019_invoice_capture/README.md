# SAW019 — Invoice Capture (same-box OCR)

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#19](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/19) |
| **Slug** | `SAW019_invoice_capture` |
| **Dev host** | `3.107.53.69` (installed through `sql/24` + JAR `7.1.0.202607151950`) |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — full agent runbook (processes, role Access table, SQL order, JAR, host OCR deps, smoke).

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Invoice Capture inbox in iDempiere: attach PDF → **Process Selected Invoice** anytime (or optional nightly batch). Shared OCR + Draft AP Vendor Invoice on the same EC2 (`pdftotext` + Tesseract). No separate OCR worker.

## Source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.invoicecapture/` |
| Deploy script | `…/deploy.sh` (OCR packages + JAR + all SQL + restart) |
| Shared service | `com.aberp.invoicecapture.service.InvoiceCaptureService` |
| AD SQL | `sql/00` … `sql/24` + `sql/08-verify.sql` |

## Processes (Search key)

| Access | Name | Search key |
|--------|------|------------|
| Window | Invoice Capture | — |
| Process | Upload Invoice PDF | `AbERP_InvoiceCapture_UploadPdf` |
| Process | Process Selected Invoice | `AbERP_InvoiceCapture_ProcessSelected` |
| Process | Process Invoice Capture Batch | `AbERP_InvoiceCapture_ProcessBatch` |

Java: `UploadInvoicePdf`, `ProcessSelectedInvoice`, `ProcessInvoiceCaptureBatch`.

## Dependencies

| Kind | Dependency |
|------|------------|
| Host | `poppler-utils`, `tesseract-ocr` |
| AD / data | Entity `Ab_ERP`; AP Invoice doc type (`API`); active `C_Charge` (prefer **Invoice Capture**) |
| Smoke windows | Invoice (Vendor), Purchase Order (zoom / Complete) |
| App | None |

## Packs

- Staging: `Downloads/AbilityERP-ClientUpdate-SAW019_invoice_capture-20260715`
- Prod: `Downloads/AbilityERP-ProdUpdate-SAW019_invoice_capture-20260715`
