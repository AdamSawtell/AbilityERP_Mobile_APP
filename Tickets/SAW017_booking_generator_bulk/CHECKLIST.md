# SAW017 — Checklist

## Design / discovery

- [x] Host discovery (HCO Test): all `Generate*` processes + paras — see `hco/`
- [x] Locate Generate Bookings JAR — patched `7.1.12` (no serviceopportunity Require-Bundle)
- [x] Standards / block / Invoice Rule / exit-date filters documented
- [ ] Design sign-off (Amber / Jason + AbERP) optional after HCO smoke

## Build

- [x] Additive bulk process plugin `com.aberp.bookinggenerator.bulk`
- [x] AD SQL (process, paras, button, menu, Admin grants) — UU-safe
- [x] Delegate to existing Generate Bookings per selected row
- [x] Run-level dates applied to each BG
- [x] Standards / POS / Quote / template / Do Not Use filters
- [x] Irregular / STR opt-in
- [x] Process log (ok / skipped / failed)
- [x] Invoice Rule force on created SBs
- [x] DocAction list = `BookingGen_DocList` (not core `_Document Action`) — `sql/02-fix-docaction-list.sql`

## Staging loop (HCO Test)

- [x] Preflight + install generator stack + bulk JAR/SQL
- [x] WebUI smoke — single Generate Bookings (BG `2001124` → SB `53320`, InvoiceRule `I`, DR)
- [x] WebUI smoke — Bulk STR block (Activity Short Term Accommodation, Include STR=Y, 1–7 Aug 2026) → `ok=3`, SB `53323` InvoiceRule `I`
- [ ] Packs (ClientUpdate + ProdUpdate)

## Packs / handoff

- [ ] Update DEPLOY.md with ordered SQL including `02-fix-docaction-list.sql`
- [ ] Update EXTERNAL-SUMMARY.md for delivery
- [ ] ClientUpdate pack + thin ProdUpdate pack
- [ ] GitHub issue → done when accepted
