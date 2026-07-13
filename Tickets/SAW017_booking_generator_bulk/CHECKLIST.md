# SAW017 — Checklist

## Design / discovery

- [x] Host discovery (HCO Test): all `Generate*` processes + paras (Bookings, Timesheets, Shifts) — see `hco/`
- [x] Locate Generate Bookings JAR — **MISSING on HCO Test + seed** (AD only). Blocker: obtain from Flamingo/Logilite
- [x] Standards filter — ops query **STANDARDS** = Description STANDARD* (~270); DocType Standard preferred
- [x] Block dimension — `C_Activity_ID` + Description tokens (DO/SIL/IRR/STR); SB month queries on `C_Order`
- [x] Invoice Rule — BG has `InvoiceRule` I/D; Ready to Claim `AbERP_Ready_Claim_Rule` (ATV/MT)
- [x] Exit date — `c_bpartner.aberp_date_support_ceased`; Day Options = `*Do Not Use**` activities; waiting-on-plan = no BG column (Description/guidance)
- [ ] Design sign-off (Amber / Jason + AbERP) after JAR availability confirmed
- [ ] Install Generate Bookings JAR on HCO Test and smoke single-record generate

## Build

- [ ] BG type or Include-in-bulk column (if required) — UU-safe SQL
- [ ] Bulk process plugin + AD (params, button/Info, Admin grants)
- [ ] Delegate to existing Generate Bookings per selected row
- [ ] Run-level dates + per-BG override
- [ ] Standards / POS / Quote / template filters
- [ ] Irregular / STR opt-in
- [ ] Exclusion skips + process log (created / skipped / failed)
- [ ] Invoice Rule on created SBs

## Staging loop

- [ ] Preflight on non-prod
- [ ] Install JAR + SQL
- [ ] WebUI smoke (blocks, dates, exclusions, Invoice Rule)
- [ ] Fix until green

## Packs / handoff

- [ ] Update DEPLOY.md with real paths/versions
- [ ] Update EXTERNAL-SUMMARY.md for delivery
- [ ] ClientUpdate pack + thin ProdUpdate pack
- [ ] GitHub issue → done when accepted
