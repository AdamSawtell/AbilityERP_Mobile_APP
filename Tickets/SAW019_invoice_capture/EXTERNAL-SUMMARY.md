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
- Successfully processed rows with a linked invoice will not create a second Vendor Invoice

## Impact / who is affected

Accounts payable / finance users who receive supplier invoices as PDFs. AbilityERP Admin can open and run the feature after install.

## How to test

1. Log in as AbilityERP Admin (or Admin)
2. Open **Invoice Capture** from the menu
3. Create a record and attach a vendor invoice PDF
4. Click **Process Selected Invoice**
5. Confirm Last Result message and, when matched, zoom to Draft Vendor Invoice
6. Open **Processing Log** and confirm a new entry

## Access

**AbilityERP Admin** (and Admin) can use the Invoice Capture window and both processes after install and re-login / Cache Reset.
