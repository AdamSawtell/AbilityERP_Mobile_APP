# SAW017 — Checklist

## Design / discovery

- [x] Host discovery (HCO Test) — see `hco/DISCOVERY.md`
- [x] Generate Bookings JAR — patched `7.1.12` (no serviceopportunity Require-Bundle)
- [x] Standards / block / Invoice Rule / exit-date filters documented

## Build

- [x] Additive bulk process plugin `com.aberp.bookinggenerator.bulk`
- [x] AD SQL (process, paras, button, menu, Admin grants) — UU-safe
- [x] Delegate to existing Generate Bookings per selected row
- [x] Run-level dates / Standards filters / Irregular+STR opt-in / Invoice Rule
- [x] DocAction = `BookingGen_DocList` (`02-fix-docaction-list.sql`)
- [x] Yes/No display type 20 (`03-fix-yesno-display.sql`)
- [x] Post-run process summary (header + per-row + totals) — JAR `7.1.0.202607160715` (summary-only; no filter/delegate change)
- [x] Redeploy summary JAR on `13.210.248.141` (2026-07-16) — built on host, `bundles.info` → `…160715`, WebUI 200 after restart
- [x] Per-row summary adds BP, Invoice Partner, Target DocType — JAR `…160730` on `13.210.248.141` (2026-07-16)

## Staging loop (HCO Test) — E2E 2026-07-13 **PASS**

Evidence: [`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md)

- [x] Install + Cache Reset + single + bulk smoke
- [x] Revert temporary smoke AD defaults

## Packs / agent handoff

- [x] `DEPLOY.md` complete for agent install on another build
- [x] `EXTERNAL-SUMMARY.md` customer-ready
- [x] Bulk JAR in `Tickets/SAW017_…/jar/`
- [x] ClientUpdate pack: `Downloads\AbilityERP-ClientUpdate-SAW017_booking_generator_bulk-20260714\`
- [x] ProdUpdate pack: `Downloads\AbilityERP-ProdUpdate-SAW017_booking_generator_bulk-20260714\`
- [x] GitHub #17 Deploy section updated
- [ ] Mark GitHub issue **done** when customer accepts / prod installed
