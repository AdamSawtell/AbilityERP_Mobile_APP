# SAW021 — Checklist

## Staging (develop / HCO Test `13.210.248.141`)

- [x] Discovery: table, columns, child Unavailable Days, overlap counts
- [ ] Confirm scope extras (pattern column / clash / roster-day filter)
- [ ] Scaffold plugin `com.aberp.unavailability.planning` from Leave Planning
- [ ] Preflight + Info Window SQL (UUID-safe)
- [ ] JAR: banner, Export CSV, Support Location EXISTS, date overlap harden
- [ ] Review: SQL verify + WebUI smoke (Jan 2027 ≈ 49 rows)
- [ ] AbilityERP Admin + Admin / Rostering / P&C access grants
- [ ] Staging + thin Prod Downloads packs
- [ ] Mark done when packs ready + EXTERNAL-SUMMARY accepted

## Acceptance mapping (v1 parity)

- [ ] Unavailability Planning Info Window
- [ ] Date-only Planning Start/End mandatory; overlap matching
- [ ] Support Location blank = all (roster path)
- [ ] Approver Status + Employee criteria
- [ ] Summary banner by Approver Status; clickable filters
- [ ] Status cell colours; grid readonly
- [ ] Zoom to Ongoing Unavailability
- [ ] Export CSV of matching query
- [ ] Menu under same area as Leave Planning / Ability ERP
