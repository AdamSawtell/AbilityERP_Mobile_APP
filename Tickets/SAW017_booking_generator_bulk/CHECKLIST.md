# SAW017 — Checklist

## Design / discovery

- [x] Host discovery (HCO Test) — see `hco/DISCOVERY.md`
- [x] Generate Bookings JAR — patched `7.1.12` (no serviceopportunity Require-Bundle)
- [x] Standards / block / Invoice Rule / exit-date filters documented

## Build

- [x] Additive bulk process plugin `com.aberp.bookinggenerator.bulk`
- [x] AD SQL (process, paras, button, menu, Admin grants) — UU-safe
- [x] Delegate to existing Generate Bookings per selected row
- [x] Run-level dates applied to each BG
- [x] Standards / POS / Quote / template / Do Not Use filters
- [x] Irregular / STR opt-in
- [x] Process log (ok / skipped / failed)
- [x] Invoice Rule force on created SBs
- [x] DocAction list = `BookingGen_DocList` — `sql/02-fix-docaction-list.sql`

## Staging loop (HCO Test) — E2E 2026-07-13 **PASS**

Evidence: [`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md)

- [x] Preflight + install generator stack + bulk JAR/SQL
- [x] Cache Reset
- [x] Single Generate Bookings — BG `2001124` → SB `53324` InvoiceRule `I` DR (Sep 1–7)
- [x] Bulk STR block — `ok=3` → SBs `53325`, `53326` InvoiceRule `I`
- [x] Revert any temporary smoke AD defaults (DateFrom/DateTo/Activity/IncludeSTR)

## Packs / handoff

- [x] DEPLOY.md ordered SQL + smoke notes
- [ ] EXTERNAL-SUMMARY.md final polish for customer
- [ ] ClientUpdate pack + thin ProdUpdate pack
- [ ] GitHub issue → done when packs accepted
