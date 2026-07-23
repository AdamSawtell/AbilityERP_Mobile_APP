# SAW033 — Checklist

## Ticket setup

- [x] Allocate `SAW033` in `docs/TICKETS.md`
- [x] Create `Tickets/SAW033_hco_theme_plugin/`
- [x] Scope review + host probe (`3.27.122.147`)
- [x] GitHub issue `ticket` + `in-progress` ([#33](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/33))
- [x] Scaffold `idempiere-plugins/org.hco.ui.theme/`

## Build

- [x] MANIFEST (LF) + lang-addon theme module
- [x] `custom.css.dsp` brand overrides (+ dark-mode contrast)
- [x] Images: logo, favicon, logo-mobile
- [x] Login branding ZUL
- [x] Package JAR `7.1.0.2026072317`

## Staging loop (`3.27.122.147`)

- [x] Preflight
- [x] Install (ui.zk inject + sysconfig) + restart
- [x] WebUI smoke (login, desktop, toolbar/tabs/grid, favourites, contrast)
- [x] Document Jetty fragment limitation + deploy method
- [x] Append HCO learnings

## Packs / handoff

- [x] ClientUpdate pack `AbilityERP-ClientUpdate-SAW033_hco_theme_plugin-20260723`
- [x] ProdUpdate pack `AbilityERP-ProdUpdate-SAW033_hco_theme_plugin-20260723`
- [x] EXTERNAL-SUMMARY ready to paste
- [x] DEPLOY.md agent-ready (packs primary)
- [ ] Production promote (separate agent / step)
