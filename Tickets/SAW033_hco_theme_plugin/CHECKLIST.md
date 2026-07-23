# SAW033 — Checklist

## Ticket setup

- [x] Allocate `SAW033` in `docs/TICKETS.md`
- [x] Create `Tickets/SAW033_hco_theme_plugin/`
- [x] Scope review + host probe (`3.27.122.147`)
- [x] GitHub issue `ticket` + `in-progress` ([#33](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/33))
- [x] Scaffold `idempiere-plugins/org.hco.ui.theme/`

## Build

- [x] MANIFEST (LF) + lang-addon theme module
- [x] `custom.css.dsp` brand overrides
- [x] Images: logo, favicon, logo-mobile
- [x] Login branding ZUL
- [x] Package JAR `7.1.0.2026072302`

## Staging loop (`3.27.122.147`)

- [x] Preflight
- [x] Install (ui.zk inject + sysconfig) + restart
- [x] WebUI smoke (login, desktop, Employee toolbar/tabs/grid)
- [x] Document Jetty fragment limitation + deploy method
- [x] Append HCO learnings

## Packs / handoff

- [ ] ClientUpdate pack
- [ ] ProdUpdate pack (thin)
- [x] EXTERNAL-SUMMARY draft
- [ ] Production promote (separate step)
