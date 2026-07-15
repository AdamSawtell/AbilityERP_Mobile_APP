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

## Purchase Order link (2026-07-14)

- Capture field **Purchase Order** (`C_Order_ID`) — Search, filtered to completed/closed POs for the vendor.
- Process extracts `Purchase Order:` / `PO` from PDF; matches `C_Order.DocumentNo`.
- If matched (or user picks PO): Draft AP invoice lines copy **open qty** from PO lines (`C_OrderLine_ID` set); invoice also stores `C_Order_ID`.
- If no PO: existing single Charge-line draft path.
- Test PDFs in Downloads: `SAW019_PO_Safety_Gear_Pro_800013.pdf`, `SAW019_PO_Adelaide_Property_Managers_800014.pdf`, `SAW019_PO_TechWorks_Australia_800017.pdf`.

## PO → Complete → Matched PO (2026-07-15 Phase 1–3)

- JAR `7.1.0.202607151700` + `sql/15-open-po-val-rule.sql`.
- Amount check: invoice total must be within ±$1 of PO **GrandTotal** or open line-net; else **Requires Review**.
- PO Search/val rule prefers POs with open qty.
- Last Result distinguishes draft from PO / charge line / review.
- **Proof (dev):** Capture `IC-1000005` → Vendor Invoice `1000009` (`C_Invoice_ID=1000016`) linked to PO `800013`. Document Action **Complete** → DocStatus CO; PO line QtyInvoiced 0→1. **Matched POs tab empty** — AbilityERP PO lines are **charges** (PPE - Direct); core `M_MatchPO` fills for **product** lines. Zoom to PO + Vendor Invoice confirmed (field Search refs).
- Packs: `Downloads/AbilityERP-ClientUpdate-SAW019_invoice_capture-20260715`, `Downloads/AbilityERP-ProdUpdate-SAW019_invoice_capture-20260715`.

## No PK nor FK on first save (2026-07-15)

- Cause: session language `en_AU` (system language) — `POInfo` INNER JOINs `AD_Element_Trl`; missing trl dropped the IsKey column.
- Fix: `sql/16-fix-element-trl.sql` (+ restart / Cache Reset). Verify PK appears under en_AU join.

## Menu not visible under English (AU) (2026-07-15)

- Same pattern: missing `AD_Menu_Trl` (and window/tab/field/process trls).
- Fix: `sql/17-fix-menu-trl-access.sql`. Menu path: **Ability ERP → Invoice Capture**.
- Role: **AbilityERP Admin** (window access). Logout/in after apply.

## Clean capture layout (2026-07-15)

- `sql/18-clean-capture-layout.sql`: hide Org, File Path, Tax ID, Active, Processed; Extracted Text after process.
- `sql/19-show-extracted-text.sql`: Extracted Text visible when `@Processed@=Y`, full width, 10 lines.
- `sql/20-progressive-capture-ux.sql`: staged UX — (1) Name + Upload, (2) Doc No + Last Result + Process after upload, (3) Invoice Details + OCR groups after process; buttons hidden. Upload sets `LastResult` as the stage-2 signal.
- `sql/21-help-tooltips.sql`: Window/Tab/Field/Process Description (tooltip) + Help (How-To / Context Help) for the guided flow.
- Batch (`ProcessInvoiceCaptureBatch` / JAR `…1950`): only `Processed='N'` — never re-runs manual or prior-batch results. Manual Process can still retry review/error statuses.
- `sql/23-show-pending-status.sql`: show **Capture Status** after Upload (Pending = queued for overnight batch / manual Process); keep it after Process for the outcome.
- `sql/24-fix-displaylogic.sql`: fix Display Logic — nested `@Processed@=Y | (...)` hid Document/Status/Last Result in ZK; use `@LastResult@!'' | @Processed@=Y`.
- Two-column pairs (DocNo/Status, BP/PO, Invoice No/Date); **Upload PDF** + **Process** half-width same line.
- Cache Reset / close+reopen Invoice Capture window after apply.

## Browser bugs found / fixed (2026-07-14)

1. **PK field missing on tab** → WebUI `Record_ID=0` → Attachment greyed out; Upload/Process said “Save the record first”. Fixed in `sql/11-fix-pk-field.sql` (+ `04` includes hidden PK fields).
2. **Service columns not updateable** (`LastResult` etc.) → `ColumnReadonly` on process. Columns are now updateable; UI fields stay read-only.
3. **New record would not save** (compound):
   - Login Org `*` left Organization blank → `sql/12-fix-org-default-docno.sql` (Org SQL default + AccessLevel Client-only + DocumentNo sequence).
   - Missing hidden **Client** field → WebUI `AD_Client_ID=-1` → `AccessTableNoUpdate missing=C` → “Changes ignored”. Fixed in `sql/13-fix-client-field.sql` (+ Client field in `04`). Client column default `@#AD_Client_ID@`.
4. After fixes: **New** → Org=AbilityERP, Status=Pending → **Save** creates `IC-######`. Cache Reset / re-open window after SQL.

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
| New record Save | **PASS** — WebUI New→Save → `IC-1000000` (Client+Org=1000002, Pending) after Client field fix |
| Dev instance type | **t2.medium** (user target described as t2.xlarge) |

WebUI password used for smoke: SuperUser / flamingo (DB password pattern on this host).
