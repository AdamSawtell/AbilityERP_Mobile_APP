# SAW019 — Notes

## Decisions

- Same-box OCR: `pdftotext` (poppler) then Tesseract — no separate OCR EC2
- Shared `InvoiceCaptureService` for manual + batch
- Anytime **Process Selected Invoice** is primary; nightly scheduler is catch-up (host idle)
- Draft AP Invoice only; human completes later
- Charge line: prefer Charge named `Invoice Capture`, else first active Charge

## Dev host

- `3.107.53.69` (currently t2.medium in discovery — production target described as t2.xlarge)
- SSH key: `AbilityERP_Development_Keypair_Shared.pem`

## HCO Future Deployments variables

(pending first HCO install)

## Attachment (2026-07-14)

- Standard **Window - Attachment** moved to main toolbar (`isshowmore=N`) — was under More/vertical overflow.
- Added **Upload Invoice PDF** button/process (file picker → AD_Attachment).
- Flow: Save capture row → Upload Invoice PDF (or paperclip) → Process Selected Invoice.

## Browser bugs found / fixed (2026-07-14)

1. **PK field missing on tab** → WebUI `Record_ID=0` → Attachment greyed out; Upload/Process said “Save the record first”. Fixed in `sql/11-fix-pk-field.sql` (+ `04` includes hidden PK fields).
2. **Service columns not updateable** (`LastResult` etc.) → `ColumnReadonly` on process. Columns are now updateable; UI fields stay read-only.
3. Smoke org `*` / `ad_org_id=0` repaired to AbilityERP; `AD_Org_ID` default `@#AD_Org_ID@`.

## Smoke log (2026-07-14 / 3.107.53.69)

| Check | Result |
|-------|--------|
| OCR packages | `poppler-utils` + `tesseract` installed |
| pdftotext sample PDF | PASS (invoice fields readable) |
| SQL verify | Window/process/button/scheduler/Admin access PASS |
| OSGi bundle | `com.aberp.invoicecapture` **ACTIVE** |
| WebUI login | SuperUser / AbilityERP Admin PASS |
| Menu search | Invoice Capture + Process Invoice Capture Batch visible |
| Attachment toolbar | PASS (enabled after PK field fix) |
| End-to-end process | **PASS** — Draft Vendor Invoice `C_Invoice_ID=1000013` (status DR); capture `SMOKE-001` → status OK |
| Invoice No parse | Fixed regex (`inv` matched inside `INVOICE` → `OICE`); redeployed JAR `7.1.0.202607142000` |
| Dev instance type | **t2.medium** (user target described as t2.xlarge) |

WebUI password used for smoke: SuperUser / flamingo (DB password pattern on this host).
