# SAW019 — Deploy (Invoice Capture)

Agent install runbook for another iDempiere build.

## Prerequisites

- SSH to host; `psql` on `idempiere` / `adempiere`
- OSGi console or `bundles.info` + restart rights
- Host packages: `poppler-utils`, `tesseract-ocr` (install if missing)
- Entity type `Ab_ERP` present
- AP Invoice (`DocBaseType=API`) doc type on client
- At least one active `C_Charge` (prefer name **Invoice Capture**)

## Plugin

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.invoicecapture/` |
| Symbolic name | `com.aberp.invoicecapture` |
| Version | `7.1.0.202607141930` |
| JAR | `com.aberp.invoicecapture_7.1.0.202607141930.jar` |

On host:

```bash
cd /path/to/com.aberp.invoicecapture
bash deploy.sh
```

Or: `bash build.sh` → copy JAR to `plugins/` + `customization-jar/` → append `bundles.info` → apply SQL below → restart iDempiere (**do not** wipe OSGi cache).

## SQL order (UU-safe)

1. `sql/00-preflight.sql`
2. `sql/01-create-tables.sql`
3. `sql/02-status-reference.sql`
4. `sql/03-ad-table-columns.sql`
5. `sql/04-window-tabs-fields.sql`
6. `sql/05-processes-button.sql`
7. `sql/06-menu-access.sql`
8. `sql/07-scheduler.sql`
9. `sql/09-batch-menu.sql`
10. `sql/10-enable-attachment.sql`
11. `sql/11-fix-pk-field.sql`
12. `sql/12-fix-org-default-docno.sql`
13. `sql/13-fix-client-field.sql`
14. `sql/14-add-po-link.sql`
13. `sql/08-verify.sql`

Never hardcode `AD_*_ID` targets across clients — scripts resolve by `*_UU` / name.

## AbilityERP Admin access

Granted in SQL by role **name**:

- Window access: Invoice Capture → **AbilityERP Admin**, **Admin**, **System Administrator**
- Process access: Process Selected Invoice + Process Invoice Capture Batch → same roles

After install: **Cache Reset** or logout/in. On HCO, SuperUser may need **Admin** role selected.

## Fixed AbERP UUs (owned)

| Object | UU |
|--------|-----|
| Table AbERP_InvoiceCapture | `19a01901-c0d4-4f01-8e15-000000000001` |
| Table AbERP_InvoiceCaptureLog | `19a01902-c0d4-4f01-8e15-000000000001` |
| Window | `19a01903-c0d4-4f01-8e15-000000000001` |
| Process Selected | `19a01908-c0d4-4f01-8e15-000000000001` |
| Process Batch | `19a01909-c0d4-4f01-8e15-000000000001` |
| Scheduler | `19a0190a-c0d4-4f01-8e15-000000000001` |

## Smoke

1. Login AbilityERP Admin → menu **Invoice Capture**
2. New record → attach PDF (or File Path to server PDF)
3. **Process Selected Invoice**
4. Expect clear Last Result; on success, zoom **Vendor Invoice** (Draft)
5. Processing Log tab has a new row (prior logs kept)
6. Re-process succeeded row → refuses duplicate create

## Architecture note

Same-box OCR (no OCR EC2). Anytime manual process is primary; nightly scheduler is optional catch-up.
