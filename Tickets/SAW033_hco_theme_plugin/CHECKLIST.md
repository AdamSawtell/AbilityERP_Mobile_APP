# SAW033 — Checklist

## Ticket setup

- [x] Allocate `SAW033` in `docs/TICKETS.md`
- [x] Create `Tickets/SAW033_hco_theme_plugin/`
- [x] Scope review + host probe (`3.27.122.147`)
- [x] GitHub issue `ticket` + `in-progress` ([#33](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/33))
- [ ] Scaffold `idempiere-plugins/org.hco.ui.theme/`

## Build

- [ ] MANIFEST / plugin.xml theme extension
- [ ] `hco.css.dsp` (panels, buttons, inputs, menus, grids, toolbar tiles, tabs, dialogs, status, spinner)
- [ ] Images: logo, favicon, logo-mobile
- [ ] Login branding
- [ ] Compile against iDempiere 7 target / package JAR

## Staging loop (`3.27.122.147`)

- [ ] Preflight
- [ ] OSGi install/start
- [ ] Select theme / Cache Reset / re-login
- [ ] WebUI smoke (checklist in DEPLOY.md)
- [ ] Fix CSS regressions
- [ ] Append HCO learnings

## Packs / handoff

- [ ] ClientUpdate pack
- [ ] ProdUpdate pack (thin)
- [ ] EXTERNAL-SUMMARY ready for customer paste
- [ ] Production promote flagged for deployment agent (not this ticket’s install)
