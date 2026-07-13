# SAW015 — Checklist

## Ticket bootstrap

- [x] Allocate SAW015; GitHub #15; Agents chat renamed
- [x] `Tickets/SAW015_skip_dates_copy_from/` scaffold
- [x] `docs/TICKETS.md` registry row

## Discovery

- [x] Service Booking copy-lines (`CopyFrom` / `CopyFromOrder`)
- [x] Skip Dates / Dates schema + UUs on HCO
- [x] JAR + SvrProcess chosen

## Implementation

- [x] Process + parameter (source Skip Dates)
- [x] Copy logic (new IDs, target FK, source read-only)
- [x] Date-review warning / confirmation
- [x] Copy-count success message
- [x] Button on Skip Dates header (`B`)
- [x] AbilityERP Admin + Admin process access
- [x] Preflight / install / verify / rollback SQL
- [x] Fixed UUs for new AbERP objects

## Staging loop (HCO Test)

- [x] Preflight
- [x] Install JAR + SQL
- [x] Stop/start iDempiere; bundle ACTIVE
- [x] Cache Reset / re-login
- [x] WebUI smoke (copy 12, warning, source unchanged, independent IDs)

## Packs / UAT

- [x] Staging pack `AbilityERP-ClientUpdate-SAW015_…-20260713`
- [x] Thin prod pack `AbilityERP-ProdUpdate-SAW015_…-20260713`
- [x] Deployed to HCO Test for customer UAT
- [x] Update EXTERNAL-SUMMARY / DEPLOY / NOTES
- [x] GitHub issue #15 Deploy section complete (agent can install from issue + DEPLOY.md)
- [x] `Tickets/AGENT-READY.md` lists SAW015 Yes (JAR+SQL)
- [ ] GitHub → done when customer UAT accepted
