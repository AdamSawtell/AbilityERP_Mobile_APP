# Invoice Capture — external summary

## Windows / processes / objects affected

| Object | Type | Notes |
|--------|------|--------|
| Invoice Capture | Window | Inbox for vendor invoice PDFs |
| Invoice Capture | Tab | Header: status, PDF path, BP, amounts, Vendor Invoice zoom |
| Processing Log | Tab | Append-only history of process attempts |
| Upload Invoice PDF | Process / button | Attach a PDF to the capture row (file picker) |
| Purchase Order | Field on Invoice Capture | Optional link to a vendor Purchase Order (auto-matched from PDF or chosen) |
| Process Selected Invoice | Process / button | Process the open capture record anytime |
| Process Invoice Capture Batch | Process + nightly scheduler | Catch-up for eligible pending rows |
| Attachment (toolbar) | Toolbar | Paperclip on main toolbar for Invoice Capture / other windows |
| Draft AP Invoice | Document | Created for review (not completed) |

## What’s done

Finance can put a vendor invoice PDF into iDempiere and process it immediately, without waiting overnight. The system extracts text (digital PDF first, scanned OCR fallback), matches vendor, checks duplicates, and creates a **Draft** AP Vendor Invoice with the PDF attached.

## What changed (behaviour)

- New **Invoice Capture** menu/window
- Attach PDF (or server file path) on a capture row
- **Process Selected Invoice** runs the full pipeline on that row only
- Optional nightly batch uses the **same** pipeline
- Capture status and Last Result explain outcomes (draft created, vendor not matched, possible duplicate, validation failed, PDF unreadable, processing error)
- Linked Vendor Invoice field zooms to the Draft invoice
- Previous processing logs are kept; each attempt adds a log line
- Optional **Purchase Order** link: OCR/user PO# → draft AP lines from open PO lines; Zooms to PO like Vendor Invoice
- Amount vs PO mismatch (±$1 of order total or open line-net) → **Requires Review** (no draft yet)
- Successfully processed rows with a linked invoice will not create a second Vendor Invoice
- Completing the Draft Vendor Invoice updates PO invoiced qty; the invoice **Matched POs** tab populates for **product** PO lines (charge-only lines typically do not show MatchPO rows — iDempiere core behaviour)

## Impact / who is affected

Accounts payable / finance users who receive supplier invoices as PDFs. AbilityERP Admin can open and run the feature after install.

## How to test

1. Log in as AbilityERP Admin (or Admin)
2. Open **Invoice Capture** from the menu
3. Create a record and attach a vendor invoice PDF (prefer one with a known PO#)
4. Click **Process Selected Invoice**
5. Confirm Last Result (“Draft from PO …” or charge-line / review message)
6. Zoom **Purchase Order** and **Vendor Invoice**; on the draft invoice, confirm PO Line on the line tab
7. Document Action → Complete (open period) → confirm PO Qty Invoiced; check Matched POs if lines are products
8. Open **Processing Log** and confirm a new entry

## Access

**AbilityERP Admin** (and Admin) can use Invoice Capture after install and re-login / Cache Reset. Role dependencies:

| Access | Name | Search key |
|--------|------|------------|
| Window | Invoice Capture | — |
| Process | Upload Invoice PDF | `AbERP_InvoiceCapture_UploadPdf` |
| Process | Process Selected Invoice | `AbERP_InvoiceCapture_ProcessSelected` |
| Process | Process Invoice Capture Batch | `AbERP_InvoiceCapture_ProcessBatch` |
