# SAW017 — Checklist

## Design / discovery

- [ ] Host discovery: all `Generate*` processes + paras (Bookings, Timesheets, Invoice, Roster)
- [ ] Locate Generate Bookings JAR; confirm callable API vs must wrap/duplicate
- [ ] Confirm Standards filter with ops (query SQL vs new BG column)
- [ ] Confirm block dimension (Activity / service line / other)
- [ ] Confirm Invoice Rule default behaviour
- [ ] Confirm waiting-on-plan / exit-date / Day Options field sources
- [ ] Design sign-off (Amber / Jason + AbERP)

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
