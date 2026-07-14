# com.aberp.invoicecapture

Same-box Invoice Capture for AbilityERP (SAW019).

## Behaviour

- Window **Invoice Capture** (`AbERP_InvoiceCapture`)
- Button **Process Selected Invoice** → shared `InvoiceCaptureService`
- Menu **Process Invoice Capture Batch** + nightly scheduler (optional catch-up)
- OCR: `pdftotext` (poppler) first, then **Tesseract** for scanned PDFs
- Creates **Draft** AP Vendor Invoice, links `C_Invoice_ID`, append-only log

## Host deps

```bash
sudo apt-get install -y poppler-utils tesseract-ocr
```

## Deploy

```bash
bash deploy.sh
```

See `Tickets/SAW019_invoice_capture/DEPLOY.md`.
