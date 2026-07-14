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

## Smoke log (2026-07-14 / 3.107.53.69)

| Check | Result |
|-------|--------|
| OCR packages | `poppler-utils` + `tesseract` installed |
| pdftotext sample PDF | PASS (invoice fields readable) |
| SQL verify | Window/process/button/scheduler/Admin access PASS |
| OSGi bundle | `com.aberp.invoicecapture` **ACTIVE** |
| WebUI login | SuperUser / AbilityERP Admin PASS |
| Menu search | Invoice Capture + Process Invoice Capture Batch visible |
| End-to-end process run | **Pending** — host AD_Scheduler appears idle (Housekeeping last 2026-07-08); ZK menu open flaky in automation. Seed row `SMOKE-001` (id 1000000) + `/tmp/saw019-smoke/sample-invoice.pdf` ready for manual **Process Selected Invoice** |
| Dev instance type | **t2.medium** (user target described as t2.xlarge) |

WebUI password used for smoke: SuperUser / flamingo (DB password pattern on this host).
