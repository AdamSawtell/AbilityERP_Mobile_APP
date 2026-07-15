# SAW019 — Deploy to another build (agent)

**Ticket / slug:** `SAW019_invoice_capture`  
**Kind:** idempiere · **JAR:** Yes · **Status:** in-progress (dev host green through `sql/24` + JAR `…1950`)  
**GitHub:** [#19](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/19)  
**External text:** [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)

Point agents at **this file**. Do not invent alternate SQL order.

---

## Required host access

| Need | Why |
|------|-----|
| SSH to iDempiere host | Install packages, JAR, restart |
| `psql` on `idempiere` / `adempiere` | Apply ordered SQL |
| WebUI SuperUser → **AbilityERP Admin** (or **Admin** on HCO) | Smoke |
| OSGi console / `bundles.info` | Manual JAR install if not using `deploy.sh` |
| Apt install rights | `poppler-utils`, `tesseract-ocr` |

**Never** wipe `configuration/org.eclipse.osgi` after install.

---

## Agent one-liner (preferred on AbilityERP-style hosts)

```bash
cd /path/to/repo/idempiere-plugins/com.aberp.invoicecapture
chmod +x build.sh deploy.sh
# Optional: export IDEMPIERE_HOME=/opt/idempiere-server
./deploy.sh
# Builds JAR 7.1.0.202607151950, installs OCR tools, applies all SQL 00→24 + 08-verify,
# updates bundles.info, restarts iDempiere (does NOT wipe OSGi cache).
# Then: Cache Reset or logout/in → WebUI smoke as AbilityERP Admin.
```

Manual path (Downloads pack / client hosts without git): see **Packs** + OSGi steps below. Same SQL order; use JAR `com.aberp.invoicecapture_7.1.0.202607151950.jar`.

---

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.invoicecapture/` |
| Bundle-SymbolicName | `com.aberp.invoicecapture` |
| Bundle-Version | `7.1.0.202607151950` (see `META-INF/MANIFEST.MF`) |
| JAR | `com.aberp.invoicecapture_7.1.0.202607151950.jar` |
| OSGi factory | `Service-Component: invoicecapture-process.xml` |
| Require-Bundle | `org.adempiere.base`, `org.adempiere.plugin.utils` (7.1.0) |
| Entity type | `Ab_ERP` (preflight fails if missing) |

### Java classes (processes)

| Role | Class |
|------|--------|
| Upload button | `com.aberp.invoicecapture.process.UploadInvoicePdf` |
| Manual process (primary) | `com.aberp.invoicecapture.process.ProcessSelectedInvoice` |
| Batch / scheduler | `com.aberp.invoicecapture.process.ProcessInvoiceCaptureBatch` |
| Shared pipeline | `com.aberp.invoicecapture.service.InvoiceCaptureService` |
| OCR helpers | `com.aberp.invoicecapture.service.PdfTextExtractor` |
| Factory | `com.aberp.invoicecapture.factory.InvoiceCaptureProcessFactory` |

---

## Host / runtime dependencies (non-AD)

| Dependency | Required | Notes |
|------------|----------|--------|
| `poppler-utils` (`pdftotext`) | **Yes** | Digital PDF text first |
| `tesseract-ocr` | **Yes** | Scanned PDF fallback |
| Same-box only | — | No separate OCR EC2 / worker |
| Active `C_DocType` `DocBaseType=API` | **Yes** | Draft AP Vendor Invoice |
| Active `C_Charge` | **Yes** | Prefer name **Invoice Capture**; else first active charge |
| Open accounting period | For Complete smoke | Completing Draft AP updates PO Qty Invoiced |
| Attachment store | **Yes** | Standard `AD_Attachment` (Upload + paperclip) |

---

## AD objects created / owned (UU-safe)

Scripts resolve by `*_UU` / name. Do **not** hardcode `AD_*_ID` across clients. Never overwrite an existing client object’s `*_UU` when matching by name on HCO.

| Object | Name / Value | Fixed UU |
|--------|--------------|----------|
| Table | `AbERP_InvoiceCapture` | `19a01901-c0d4-4f01-8e15-000000000001` |
| Table | `AbERP_InvoiceCaptureLog` | `19a01902-c0d4-4f01-8e15-000000000001` |
| Window | Invoice Capture | `19a01903-c0d4-4f01-8e15-000000000001` |
| Tab | Invoice Capture (header) | `19a01904-c0d4-4f01-8e15-000000000001` |
| Tab | Processing Log | `19a01905-c0d4-4f01-8e15-000000000001` |
| Menu (window) | Invoice Capture | `19a01906-c0d4-4f01-8e15-000000000001` |
| List ref | `AbERP_InvoiceCapture_Status` | `19a01907-c0d4-4f01-8e15-000000000001` |
| Process | Process Selected Invoice | `19a01908-c0d4-4f01-8e15-000000000001` |
| Process | Process Invoice Capture Batch | `19a01909-c0d4-4f01-8e15-000000000001` |
| Scheduler | (batch overnight) | `19a0190a-c0d4-4f01-8e15-000000000001` |
| Process | Upload Invoice PDF | `19a01910-c0d4-4f01-8e15-000000000001` |
| Process para | FileName (upload) | `19a01911-c0d4-4f01-8e15-000000000001` |
| Menu (batch process) | Process Invoice Capture Batch | `19a0190e-c0d4-4f01-8e15-000000000001` |
| Table ref (PO Search) | | `19a0190c-c0d4-4f01-8e15-000000000001` |
| Val rule (open PO) | | `19a0190d-c0d4-4f01-8e15-000000000001` |

Menu parent: folder named **Ability ERP** (resolved by name — do not hardcode tree node IDs).

---

## Processes + role access (mandatory table)

Install SQL grants by role **name** to **AbilityERP Admin**, **Admin**, and **System Administrator** (`AD_Window_Access` / `AD_Process_Access`). If a named role is missing on the target, that grant is skipped — add manually after install.

| Access | Name | Search key | Class / notes |
|--------|------|------------|---------------|
| Window | Invoice Capture | — | Menu: Ability ERP → Invoice Capture |
| Process | Upload Invoice PDF | `AbERP_InvoiceCapture_UploadPdf` | Button `AbERP_UploadPDF`; sets Last Result `PDF uploaded: …` |
| Process | Process Selected Invoice | `AbERP_InvoiceCapture_ProcessSelected` | Button `AbERP_ProcessSelected`; anytime OCR → Draft AP |
| Process | Process Invoice Capture Batch | `AbERP_InvoiceCapture_ProcessBatch` | Menu + scheduler; **only** `Processed='N'` |

### Related (not granted by this ticket — needed for full business smoke)

| Access | Name | Search key | Why |
|--------|------|------------|-----|
| Window | Invoice (Vendor) / AP Invoice | — | Zoom linked Draft; Document Action → Complete |
| Window | Purchase Order | — | Zoom linked PO; confirm Qty Invoiced |
| Toolbar | Attachment | — | Paperclip fallback; table attachment enabled in `sql/10` |

Day users need Window + Upload + Process Selected. Batch is for menu/manual catch-up or scheduler role.

After grants: **Cache Reset** or logout/in (or Role Access Update).

---

## SQL order (UU-safe) — run all

Source: `idempiere-plugins/com.aberp.invoicecapture/sql/` (same order as `deploy.sh`).

1. `00-preflight.sql`
2. `01-create-tables.sql`
3. `02-status-reference.sql`
4. `03-ad-table-columns.sql`
5. `04-window-tabs-fields.sql`
6. `05-processes-button.sql` — Process Selected + Batch + buttons + process access
7. `06-menu-access.sql` — window menu + window access
8. `07-scheduler.sql` — overnight batch
9. `09-batch-menu.sql` — batch process menu
10. `10-enable-attachment.sql` — Upload process + attachment toolbar
11. `11-fix-pk-field.sql`
12. `12-fix-org-default-docno.sql`
13. `13-fix-client-field.sql`
14. `14-add-po-link.sql`
15. `15-open-po-val-rule.sql`
16. `16-fix-element-trl.sql` — **required** (en_AU “No PK nor FK”)
17. `17-fix-menu-trl-access.sql` — **required** (en_AU menu) + access re-check
18. `18-clean-capture-layout.sql`
19. `19-show-extracted-text.sql`
20. `20-progressive-capture-ux.sql`
21. `21-help-tooltips.sql`
22. `22-batch-unprocessed-only.sql` — process help text
23. `23-show-pending-status.sql`
24. `24-fix-displaylogic.sql` — **required** (Document/Status/Last Result visibility)
25. `08-verify.sql`

```bash
# Example manual apply (as postgres / idempiere DB user)
for f in 00-preflight.sql 01-create-tables.sql 02-status-reference.sql 03-ad-table-columns.sql \
  04-window-tabs-fields.sql 05-processes-button.sql 06-menu-access.sql 07-scheduler.sql \
  09-batch-menu.sql 10-enable-attachment.sql 11-fix-pk-field.sql \
  12-fix-org-default-docno.sql 13-fix-client-field.sql 14-add-po-link.sql \
  15-open-po-val-rule.sql 16-fix-element-trl.sql 17-fix-menu-trl-access.sql \
  18-clean-capture-layout.sql 19-show-extracted-text.sql \
  20-progressive-capture-ux.sql 21-help-tooltips.sql \
  22-batch-unprocessed-only.sql 23-show-pending-status.sql \
  24-fix-displaylogic.sql 08-verify.sql; do
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "sql/$f"
done
```

---

## JAR install (manual OSGi — client hosts)

1. Install host packages: `sudo apt-get install -y poppler-utils tesseract-ocr`
2. Copy `com.aberp.invoicecapture_7.1.0.202607151950.jar` to `plugins/` and `customization-jar/`.
3. In `bundles.info`, remove older `com.aberp.invoicecapture,*` lines; append:
   `com.aberp.invoicecapture,7.1.0.202607151950,plugins/com.aberp.invoicecapture_7.1.0.202607151950.jar,4,true`
4. Apply SQL order above.
5. Restart iDempiere (**do not** wipe OSGi cache).
6. Confirm bundle **ACTIVE** (`ss` / chuboe OSGi helpers).
7. Cache Reset or logout/in.

---

## Behaviour agents must know

1. Progressive UX: Name + **Upload PDF** → Document No / Capture Status / Last Result + **Process** → Invoice Details + OCR after `Processed=Y`.
2. Prefer **Upload Invoice PDF** over paperclip alone (Upload sets Last Result signal for stage 2).
3. Batch selects only `Processed='N'`. Manual Process can retry review/error rows.
4. Success → Draft AP only (human Completes later). Duplicate create refused when already OK with linked invoice.
5. PO match / amount ±$1 → Draft from PO lines; mismatch → Requires Review.
6. Display Logic for Document/Status/Last Result: `@LastResult@!'' | @Processed@=Y` (`sql/24`).

---

## Verify SQL (post-install)

```sql
SET search_path TO adempiere, public;
SELECT value, name, classname, isactive
FROM ad_process
WHERE value LIKE 'AbERP_InvoiceCapture%'
ORDER BY value;

SELECT r.name AS role, 'Window' AS access, w.name
FROM ad_window_access wa
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
WHERE w.ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001'
ORDER BY 1;

SELECT r.name AS role, p.value, p.name
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
WHERE p.value LIKE 'AbERP_InvoiceCapture%'
ORDER BY 1, 2;
```

Expect three processes ACTIVE + window/process rows for AbilityERP Admin (and Admin if that role exists).

---

## WebUI smoke

1. Login AbilityERP Admin (HCO: often SuperUser → **Admin**).
2. Menu **Ability ERP → Invoice Capture**.
3. New → Name → Save → **Upload Invoice PDF** → expect Capture Status **Pending**, Last Result starts with `PDF uploaded:`.
4. **Process Selected Invoice** → Last Result clear; on success zoom **Vendor Invoice** (Draft) and **Purchase Order** when linked.
5. Processing Log tab has a new row.
6. Re-process succeeded row → refuses second Vendor Invoice create.
7. Complete Draft AP in open period → PO Qty Invoiced; Matched POs for **product** lines (charge-only often empty).

Dev reference host (already installed): `3.107.53.69` — key `AbilityERP_Development_Keypair_Shared.pem`; WebUI SuperUser / flamingo → AbilityERP Admin.

---

## Packs

| Tier | Path |
|------|------|
| Staging | `Downloads\AbilityERP-ClientUpdate-SAW019_invoice_capture-20260715\` (sql through `24`, JAR `…1950`) |
| Prod thin | `Downloads\AbilityERP-ProdUpdate-SAW019_invoice_capture-20260715\` |

Prefer repo `deploy.sh` or staging pack with **full** SQL list above. Older `…20260714` packs are stale (missing UX/displaylogic/JAR 1950).

---

## HCO notes

- Follow `Tickets/HCO_Deployment/` + `.cursor/rules/hco-deployment.mdc`.
- **Never change HCO `*_UU`.** Fix AbilityERP SQL/lookups if collisions appear.
- Grant **Admin** and **AbilityERP Admin** by name; smoke as **Admin** if that is SuperUser’s role dialog.
- Append `LEARNINGS.md` + **HCO Future Deployments variables** in `NOTES.md` after first HCO install.

---

## Blockers / known pitfalls

| Symptom | Fix |
|---------|-----|
| No PK nor FK / Attachment grey | `sql/16` + Cache Reset; hidden PK field (`sql/11`) |
| Menu missing under English (AU) | `sql/17` |
| Document/Status/Last Result invisible | `sql/24` (do not use nested OR/AND Display Logic) |
| Upload/Process missing | Role missing process access rows (table above) |
| OCR empty | Host missing `pdftotext` / `tesseract` |
| Batch re-processes old rows | JAR must be `…1950` (filter `Processed='N'`) |
| New record “Changes ignored” | `sql/13` Client field + Org default (`sql/12`) |
