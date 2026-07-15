# SAW019 — Checklist

- [x] Ticket + GitHub #19
- [x] Plugin skeleton + shared service
- [x] AD SQL (table/window/button/batch/scheduler/Admin grants)
- [x] OCR tools installed on host
- [x] Deploy JAR + SQL on `3.107.53.69`
- [x] WebUI smoke: Process Selected Invoice → Draft AP Invoice (browser E2E 2026-07-14)
- [x] Fix PK field + updateable service columns (`sql/11-fix-pk-field.sql`)
- [x] Fix New/Save (`12` Org default + `13` hidden Client field) — WebUI PASS `IC-1000000`
- [x] Purchase Order link (`14` + JAR) — field, OCR match, draft from open PO lines
- [x] Test PDFs in Downloads for SGP 800013 / APM 800014 / TWA 800017
- [x] Commit + push
- [x] Client / prod Downloads packs created (2026-07-15 refresh: `…-20260715`)
- [x] Phase 1: Complete PO-linked AP → QtyInvoiced updates; MatchPO empty for charge lines (documented)
- [x] Phase 2: amount vs PO review + open-PO val rule + clearer LastResult (`15` + JAR `7.1.0.202607151700`)
- [x] Phase 3: packs + EXTERNAL/how-to notes; Zoom via Search refs (PO + Vendor Invoice)
